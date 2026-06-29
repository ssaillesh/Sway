from datetime import date, datetime
from pydantic import BaseModel, EmailStr, Field


class UserPublic(BaseModel):
    id: str
    username: str
    display_name: str
    avatar_url: str | None = None
    bio: str | None = None
    home_city: str | None = None
    home_country: str | None = None
    featured_badges: list[str] = []


class UserProfile(UserPublic):
    email: str | None = None
    total_countries: int = 0
    total_cities: int = 0
    total_km: float = 0
    total_trips: int = 0
    current_streak: int = 0
    longest_streak: int = 0


class FeaturedBadgesUpdate(BaseModel):
    # Up to 3 earned badge ids, in the order they should appear.
    badge_ids: list[str] = Field(default_factory=list, max_length=3)


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    display_name: str | None = Field(default=None, max_length=100)
    bio: str | None = Field(default=None, max_length=300)
    avatar_url: str | None = Field(default=None, max_length=500)
    home_city: str | None = Field(default=None, max_length=100)
    home_country: str | None = Field(default=None, min_length=2, max_length=2)


class TopCountry(BaseModel):
    code: str
    visits: int


class UserStats(BaseModel):
    user_id: str
    total_countries: int
    total_cities: int
    total_km: float
    total_trips: int
    current_streak: int
    longest_streak: int
    continents_visited: list[str]
    top_country: TopCountry | None = None
    transport_breakdown: dict[str, int]
    year_stats: dict[str, dict[str, float]]


class MapCountry(BaseModel):
    code: str
    name: str
    first_visited: date
    visits: int


class MapCity(BaseModel):
    name: str
    country_code: str
    lat: float | None = None
    lng: float | None = None
    visits: int


class UserMap(BaseModel):
    countries: list[MapCountry]
    cities: list[MapCity]


class GlobePoint(BaseModel):
    """A single proof-of-travel point harvested from a photo's EXIF (or placed manually)."""
    lat: float
    lng: float
    captured_at: datetime | None = None
    # "exif" = GPS came from the photo's metadata (Verified tier);
    # "manual" = user-placed (Self-reported tier).
    source: str | None = None
    photo_id: str
    trip_id: str
    thumbnail_url: str | None = None
    caption: str | None = None
    country: str | None = None   # ISO-2, reverse-geocoded
    place: str | None = None     # city/town name, reverse-geocoded


class UserGlobe(BaseModel):
    points: list[GlobePoint]
    verified_count: int   # points with EXIF GPS
    total_count: int
    country_count: int    # distinct reverse-geocoded countries


class InventoryPhoto(BaseModel):
    """Every uploaded photo, located or not, for the inventory/folder view."""
    photo_id: str
    trip_id: str
    thumbnail_url: str | None = None
    photo_url: str | None = None
    captured_at: datetime | None = None
    lat: float | None = None
    lng: float | None = None
    source: str | None = None    # exif | manual | None
    country: str | None = None
    place: str | None = None
    verified: bool               # True only when GPS came from the photo's EXIF


class PhotoInventory(BaseModel):
    photos: list[InventoryPhoto]
    verified_count: int
    unverified_count: int


class PhotoLocationUpdate(BaseModel):
    lat: float
    lng: float
