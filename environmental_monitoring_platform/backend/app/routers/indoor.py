from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas import IndoorReadingCreate, IndoorReadingResponse, IndoorIngestResponse
from app.crud import insert_indoor_reading, get_latest_indoor_reading, get_indoor_history
from app.services.alert_service import evaluate_indoor_thresholds

router = APIRouter(prefix="/api/indoor", tags=["Indoor Environment"])


@router.post("/reading", response_model=IndoorIngestResponse)
def receive_indoor_reading(reading: IndoorReadingCreate):
    """
    Ingest sensor data from ESP32 or the simulator via HTTP POST.
    Evaluates values against threshold rules and records alerts if violated.
    """
    reading_id = insert_indoor_reading(
        device_id=reading.device_id,
        temperature=reading.temperature,
        humidity=reading.humidity
    )

    alerts = evaluate_indoor_thresholds(
        device_id=reading.device_id,
        temperature=reading.temperature,
        humidity=reading.humidity
    )

    return IndoorIngestResponse(
        success=True,
        reading_id=reading_id,
        alerts_triggered=alerts
    )


@router.get("/latest", response_model=IndoorReadingResponse)
def get_latest():
    """Retrieve the most recent indoor sensor reading."""
    reading = get_latest_indoor_reading()
    if not reading:
        raise HTTPException(status_code=404, detail="No indoor readings recorded yet.")
    return reading


@router.get("/history", response_model=List[IndoorReadingResponse])
def get_history(limit: int = 50):
    """Retrieve historical indoor sensor readings."""
    return get_indoor_history(limit=limit)
