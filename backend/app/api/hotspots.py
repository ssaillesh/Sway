"""Hotspot feed — categorised POIs (party / nature / history) for Canadian cities,
sourced free from OpenStreetMap Overpass. Public (no auth), like the map endpoints.
"""
from fastapi import APIRouter, HTTPException, status, Query

from app.schemas.hotspots import (
    Hotspot, HotspotCity, HotspotCategory, HotspotMeta, HotspotFeed,
)
from app.services.hotspots import CANADA_CITIES, CATEGORIES, fetch_hotspots

router = APIRouter(prefix="/hotspots", tags=["hotspots"])


@router.get("/meta", response_model=HotspotMeta)
def meta():
    """Available cities + categories, so the client can build its controls."""
    return HotspotMeta(
        cities=[HotspotCity(key=k, label=v["label"], lat=v["lat"], lng=v["lng"])
                for k, v in CANADA_CITIES.items()],
        categories=[HotspotCategory(key=k, label=v["label"], icon=v["icon"])
                    for k, v in CATEGORIES.items()],
    )


@router.get("", response_model=HotspotFeed)
def get_hotspots(
    city: str = Query(..., description="City key, e.g. 'toronto'"),
    category: str = Query(..., description="party | nature | history"),
):
    city = city.lower()
    category = category.lower()
    if city not in CANADA_CITIES:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Unknown city")
    if category not in CATEGORIES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unknown category")
    spots = [Hotspot(**h) for h in fetch_hotspots(category, city)]
    return HotspotFeed(city=city, category=category, count=len(spots), hotspots=spots)
