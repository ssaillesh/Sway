"""Worker 3: Photo Processor.

Harvests proof-of-travel data (GPS + capture timestamp) from the photo's EXIF,
THEN strips EXIF from the stored copies (privacy), builds thumbnail + medium, and
updates the row. The harvest must happen before the strip — the stored images
intentionally carry no metadata, so the coordinates only survive on the DB row.
"""
import io
import uuid
from datetime import datetime, timezone

from PIL import Image
from PIL.ExifTags import GPSTAGS, TAGS

from app.database import SessionLocal
from app.models import TripPhoto
from app.services.geocoding import reverse_geocode
from app.services.storage import save_bytes, read_bytes_from_url
from app.workers.celery_app import celery


def _strip_exif(img: Image.Image) -> Image.Image:
    data = list(img.getdata())
    clean = Image.new(img.mode, img.size)
    clean.putdata(data)
    return clean


def _to_degrees(value) -> float | None:
    """Convert an EXIF GPS coordinate (3 rationals: deg, min, sec) to decimal degrees."""
    try:
        d, m, s = (float(v) for v in value)
        return d + m / 60.0 + s / 3600.0
    except (TypeError, ValueError, ZeroDivisionError):
        return None


def extract_exif_location(img: Image.Image) -> dict:
    """Return {captured_lat, captured_lng, captured_at} harvested from EXIF.

    Any field that can't be read is omitted. Returns {} when there is no EXIF GPS.
    This is deliberately tolerant: most shared photos have stripped or partial EXIF,
    and a missing GPS block is the common case, not an error.
    """
    result: dict = {}
    try:
        exif = img.getexif()
    except Exception:
        return result
    if not exif:
        return result

    tags = {TAGS.get(k, k): v for k, v in exif.items()}

    # Capture timestamp: prefer DateTimeOriginal from the Exif IFD, fall back to DateTime.
    raw_dt = None
    try:
        exif_ifd = exif.get_ifd(0x8769)  # ExifIFD pointer
        if exif_ifd:
            sub = {TAGS.get(k, k): v for k, v in exif_ifd.items()}
            raw_dt = sub.get("DateTimeOriginal") or sub.get("DateTimeDigitized")
    except Exception:
        pass
    raw_dt = raw_dt or tags.get("DateTime")
    if raw_dt:
        try:
            # EXIF format: "YYYY:MM:DD HH:MM:SS" (local time, no tz info available)
            dt = datetime.strptime(str(raw_dt), "%Y:%m:%d %H:%M:%S")
            result["captured_at"] = dt.replace(tzinfo=timezone.utc)
        except ValueError:
            pass

    # GPS block lives in its own IFD.
    try:
        gps_ifd = exif.get_ifd(0x8825)  # GPSInfo pointer
    except Exception:
        gps_ifd = None
    if gps_ifd:
        gps = {GPSTAGS.get(k, k): v for k, v in gps_ifd.items()}
        lat = _to_degrees(gps.get("GPSLatitude"))
        lng = _to_degrees(gps.get("GPSLongitude"))
        if lat is not None and lng is not None:
            if str(gps.get("GPSLatitudeRef", "N")).upper() == "S":
                lat = -lat
            if str(gps.get("GPSLongitudeRef", "E")).upper() == "W":
                lng = -lng
            # Reject obviously-bogus coordinates (e.g. 0,0 null island or out-of-range).
            if -90 <= lat <= 90 and -180 <= lng <= 180 and not (lat == 0 and lng == 0):
                result["captured_lat"] = lat
                result["captured_lng"] = lng

    return result


def process_photo_sync(photo_id: str) -> None:
    db = SessionLocal()
    try:
        photo = db.get(TripPhoto, uuid.UUID(str(photo_id)))
        if not photo:
            return
        raw = read_bytes_from_url(photo.photo_url)
        if not raw:
            return
        src = Image.open(io.BytesIO(raw))

        # Harvest proof-of-travel data BEFORE stripping EXIF.
        loc = extract_exif_location(src)
        if "captured_lat" in loc:
            photo.captured_lat = loc["captured_lat"]
            photo.captured_lng = loc["captured_lng"]
            photo.location_source = "exif"
            # Resolve country/place so the globe can show an exact country count.
            geo = reverse_geocode(loc["captured_lat"], loc["captured_lng"])
            if geo:
                photo.captured_country = geo["country_code"]
                photo.captured_place = geo["place"]
        if "captured_at" in loc:
            photo.captured_at = loc["captured_at"]

        img = src.convert("RGB")
        img = _strip_exif(img)

        # medium 1200x1200
        medium = img.copy()
        medium.thumbnail((1200, 1200))
        mbuf = io.BytesIO()
        medium.save(mbuf, format="JPEG", quality=85)
        photo.photo_url = save_bytes(mbuf.getvalue(), ext="jpg", subdir="photos")

        # thumbnail 400x400
        thumb = img.copy()
        thumb.thumbnail((400, 400))
        tbuf = io.BytesIO()
        thumb.save(tbuf, format="JPEG", quality=80)
        photo.thumbnail_url = save_bytes(tbuf.getvalue(), ext="jpg", subdir="thumbs")

        db.add(photo)
        db.commit()
    finally:
        db.close()


@celery.task(name="trekrank.process_photo")
def process_photo(photo_id: str) -> None:
    process_photo_sync(photo_id)
