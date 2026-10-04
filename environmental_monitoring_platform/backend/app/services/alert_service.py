from typing import List
from app.crud import get_thresholds, insert_alert


def evaluate_indoor_thresholds(device_id: str, temperature: float, humidity: float) -> List[str]:
    """
    Evaluate newly received indoor sensor readings against active thresholds.
    Creates entries in alert_logs if violations are detected.
    """
    thresholds = get_thresholds()
    triggered_alerts = []

    # 1. Temperature Check
    temp_cfg = thresholds.get("temperature")
    if temp_cfg and temp_cfg.get("is_enabled", 1):
        min_t = temp_cfg["min_value"]
        max_t = temp_cfg["max_value"]
        if temperature > max_t:
            msg = f"High Temperature Warning: {temperature:.1f}°C exceeds threshold of {max_t:.1f}°C"
            insert_alert(
                source=f"indoor:{device_id}",
                parameter="temperature",
                triggered_value=temperature,
                threshold_value=max_t,
                alert_type="HIGH",
                message=msg
            )
            triggered_alerts.append(msg)
        elif temperature < min_t:
            msg = f"Low Temperature Warning: {temperature:.1f}°C is below threshold of {min_t:.1f}°C"
            insert_alert(
                source=f"indoor:{device_id}",
                parameter="temperature",
                triggered_value=temperature,
                threshold_value=min_t,
                alert_type="LOW",
                message=msg
            )
            triggered_alerts.append(msg)

    # 2. Humidity Check
    hum_cfg = thresholds.get("humidity")
    if hum_cfg and hum_cfg.get("is_enabled", 1):
        min_h = hum_cfg["min_value"]
        max_h = hum_cfg["max_value"]
        if humidity > max_h:
            msg = f"High Humidity Warning: {humidity:.1f}% exceeds threshold of {max_h:.1f}%"
            insert_alert(
                source=f"indoor:{device_id}",
                parameter="humidity",
                triggered_value=humidity,
                threshold_value=max_h,
                alert_type="HIGH",
                message=msg
            )
            triggered_alerts.append(msg)
        elif humidity < min_h:
            msg = f"Low Humidity Warning: {humidity:.1f}% is below threshold of {min_h:.1f}%"
            insert_alert(
                source=f"indoor:{device_id}",
                parameter="humidity",
                triggered_value=humidity,
                threshold_value=min_h,
                alert_type="LOW",
                message=msg
            )
            triggered_alerts.append(msg)

    return triggered_alerts
