from typing import List, Optional, Dict, Any

try:
    from pydantic import BaseModel, Field
except ImportError:
    class BaseModel:
        def __init__(self, **kwargs):
            for k, v in kwargs.items():
                setattr(self, k, v)
        def model_dump(self):
            return self.__dict__
        def dict(self):
            return self.__dict__

    def Field(*args, **kwargs):
        return kwargs.get("default", None)


# ==========================================
# Indoor Schemas
# ==========================================
class IndoorReadingCreate(BaseModel):
    device_id: str = Field(..., example="esp32_room_node")
    temperature: float = Field(..., example=24.5)
    humidity: float = Field(..., example=55.0)


class IndoorReadingResponse(BaseModel):
    id: int
    device_id: str
    temperature: float
    humidity: float
    timestamp: str


class IndoorIngestResponse(BaseModel):
    success: bool
    reading_id: int
    alerts_triggered: List[str] = []


# ==========================================
# Outdoor Schemas
# ==========================================
class OutdoorReadingResponse(BaseModel):
    id: int
    city: str
    latitude: float
    longitude: float
    temperature: float
    humidity: float
    wind_speed: float
    weather_code: int
    weather_desc: str
    timestamp: str


# ==========================================
# Comparison Schemas
# ==========================================
class ComparisonResponse(BaseModel):
    indoor: Optional[IndoorReadingResponse] = None
    outdoor: Optional[OutdoorReadingResponse] = None
    temp_diff: Optional[float] = None        # indoor - outdoor
    hum_diff: Optional[float] = None         # indoor - outdoor
    indoor_heat_index: Optional[float] = None
    outdoor_heat_index: Optional[float] = None
    comfort_assessment: str
    status_summary: str


# ==========================================
# Alert Schemas
# ==========================================
class AlertLogResponse(BaseModel):
    id: int
    source: str
    parameter: str
    triggered_value: float
    threshold_value: float
    alert_type: str
    message: str
    timestamp: str
    is_acknowledged: bool


class ThresholdConfigSchema(BaseModel):
    parameter: str
    min_value: float
    max_value: float
    is_enabled: bool
    updated_at: str


class ThresholdUpdateSchema(BaseModel):
    min_value: float
    max_value: float
    is_enabled: bool = True


# ==========================================
# Historical Chart Schemas
# ==========================================
class HistoryPoint(BaseModel):
    timestamp: str
    indoor_temperature: Optional[float] = None
    indoor_humidity: Optional[float] = None
    outdoor_temperature: Optional[float] = None
    outdoor_humidity: Optional[float] = None


class HistoryResponse(BaseModel):
    timeframe: str
    count: int
    points: List[HistoryPoint]
