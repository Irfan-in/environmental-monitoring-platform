from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any
from app.schemas import AlertLogResponse, ThresholdConfigSchema, ThresholdUpdateSchema
from app.crud import get_alerts, acknowledge_alert, get_thresholds, update_threshold

router = APIRouter(prefix="/api/alerts", tags=["Alerts & Thresholds"])


@router.get("", response_model=List[AlertLogResponse])
def list_alerts(
    limit: int = Query(50, description="Max alerts to retrieve"),
    unacknowledged_only: bool = Query(False, description="Filter only unacknowledged alerts")
):
    """Retrieve environmental alert events."""
    raw_alerts = get_alerts(limit=limit, only_unacknowledged=unacknowledged_only)
    return [
        AlertLogResponse(
            id=a["id"],
            source=a["source"],
            parameter=a["parameter"],
            triggered_value=a["triggered_value"],
            threshold_value=a["threshold_value"],
            alert_type=a["alert_type"],
            message=a["message"],
            timestamp=a["timestamp"],
            is_acknowledged=bool(a["is_acknowledged"])
        )
        for a in raw_alerts
    ]


@router.post("/{alert_id}/ack")
def ack_alert(alert_id: int):
    """Mark an alert as acknowledged."""
    success = acknowledge_alert(alert_id)
    if not success:
        raise HTTPException(status_code=404, detail="Alert ID not found.")
    return {"success": True, "message": f"Alert {alert_id} acknowledged."}


@router.get("/thresholds", response_model=List[ThresholdConfigSchema])
def list_thresholds():
    """Get active threshold boundaries."""
    cfgs = get_thresholds()
    return [
        ThresholdConfigSchema(
            parameter=p,
            min_value=cfg["min_value"],
            max_value=cfg["max_value"],
            is_enabled=bool(cfg.get("is_enabled", 1)),
            updated_at=cfg["updated_at"]
        )
        for p, cfg in cfgs.items()
    ]


@router.put("/thresholds/{parameter}")
def set_threshold(parameter: str, body: ThresholdUpdateSchema):
    """Update threshold limits for a specific parameter (temperature or humidity)."""
    if parameter not in ["temperature", "humidity"]:
        raise HTTPException(status_code=400, detail="Invalid parameter. Must be 'temperature' or 'humidity'.")
    
    update_threshold(
        parameter=parameter,
        min_val=body.min_value,
        max_val=body.max_value,
        is_enabled=body.is_enabled
    )
    return {
        "success": True,
        "parameter": parameter,
        "min_value": body.min_value,
        "max_value": body.max_value,
        "is_enabled": body.is_enabled
    }
