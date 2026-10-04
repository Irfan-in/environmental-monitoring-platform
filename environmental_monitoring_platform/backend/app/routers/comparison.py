from app.schemas import ComparisonResponse, IndoorReadingResponse, OutdoorReadingResponse
from app.crud import get_latest_indoor_reading, get_latest_outdoor_reading
from app.services.weather_service import fetch_open_meteo_weather
from app.services.metrics import compute_heat_index, evaluate_comfort

try:
    from fastapi import APIRouter
    router = APIRouter(prefix="/api/comparison", tags=["Indoor vs Outdoor Comparison"])
except ImportError:
    class DummyRouter:
        def __init__(self, *args, **kwargs): pass
        def get(self, *args, **kwargs): return lambda f: f
        def post(self, *args, **kwargs): return lambda f: f
        def put(self, *args, **kwargs): return lambda f: f
    router = DummyRouter()


@router.get("", response_model=ComparisonResponse)
def get_comparison():
    """
    Compare current indoor IoT readings against outdoor weather metrics.
    Calculates differences, heat indices, and comfort evaluation.
    """
    indoor = get_latest_indoor_reading()
    outdoor = get_latest_outdoor_reading()

    # If outdoor is missing, attempt to fetch it
    if not outdoor:
        fetch_open_meteo_weather()
        outdoor = get_latest_outdoor_reading()

    indoor_obj = IndoorReadingResponse(**indoor) if indoor else None
    outdoor_obj = OutdoorReadingResponse(**outdoor) if outdoor else None

    if not indoor_obj or not outdoor_obj:
        return ComparisonResponse(
            indoor=indoor_obj,
            outdoor=outdoor_obj,
            temp_diff=None,
            hum_diff=None,
            indoor_heat_index=None,
            outdoor_heat_index=None,
            comfort_assessment="Insufficient Data",
            status_summary="Waiting for both indoor and outdoor data sources to synchronize."
        )

    temp_diff = round(indoor_obj.temperature - outdoor_obj.temperature, 1)
    hum_diff = round(indoor_obj.humidity - outdoor_obj.humidity, 1)

    in_hi = compute_heat_index(indoor_obj.temperature, indoor_obj.humidity)
    out_hi = compute_heat_index(outdoor_obj.temperature, outdoor_obj.humidity)

    # Comfort Assessment Evaluation
    if 21.0 <= indoor_obj.temperature <= 26.0 and 40.0 <= indoor_obj.humidity <= 60.0:
        comfort = "Ideal Comfort Zone (ASHRAE Standard 55)"
    elif indoor_obj.temperature > 28.0:
        comfort = "Warm / Elevated Thermal Load"
    elif indoor_obj.temperature < 19.0:
        comfort = "Cool / Below Neutral Zone"
    elif indoor_obj.humidity > 65.0:
        comfort = "Humid / Potential Stuffiness"
    elif indoor_obj.humidity < 35.0:
        comfort = "Dry Air / Respiratory Caution"
    else:
        comfort = "Acceptable Indoor Conditions"

    # Status Summary
    if temp_diff < -2.0:
        summary = f"Indoor environment is {abs(temp_diff):.1f}°C cooler than outside."
    elif temp_diff > 2.0:
        summary = f"Indoor environment is {temp_diff:.1f}°C warmer than outside."
    else:
        summary = "Indoor and outdoor temperatures are closely balanced."

    return ComparisonResponse(
        indoor=indoor_obj,
        outdoor=outdoor_obj,
        temp_diff=temp_diff,
        hum_diff=hum_diff,
        indoor_heat_index=in_hi,
        outdoor_heat_index=out_hi,
        comfort_assessment=comfort,
        status_summary=summary
    )
