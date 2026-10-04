from fastapi import APIRouter, HTTPException, Query
from app.schemas import OutdoorReadingResponse
from app.crud import get_latest_outdoor_reading
from app.services.weather_service import fetch_open_meteo_weather
from app.config import DEFAULT_LATITUDE, DEFAULT_LONGITUDE, DEFAULT_CITY

router = APIRouter(prefix="/api/outdoor", tags=["Outdoor Weather"])


@router.get("/latest", response_model=OutdoorReadingResponse)
def get_latest():
    """
    Get the latest stored outdoor weather reading.
    If no outdoor data is in the database, automatically fetches from Open-Meteo.
    """
    reading = get_latest_outdoor_reading()
    if not reading:
        # Fetch fresh data
        fetch_open_meteo_weather()
        reading = get_latest_outdoor_reading()

    if not reading:
        raise HTTPException(status_code=404, detail="No outdoor weather data available.")
    return reading


@router.post("/sync", response_model=OutdoorReadingResponse)
def sync_weather(
    lat: float = Query(DEFAULT_LATITUDE, description="Latitude"),
    lon: float = Query(DEFAULT_LONGITUDE, description="Longitude"),
    city: str = Query(DEFAULT_CITY, description="City name")
):
    """
    Trigger an on-demand synchronization with the external Open-Meteo Weather API.
    """
    fetch_open_meteo_weather(lat=lat, lon=lon, city=city)
    reading = get_latest_outdoor_reading()
    if not reading:
        raise HTTPException(status_code=500, detail="Failed to fetch outdoor weather.")
    return reading
