from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from app.database import get_connection


# ==========================================
# Indoor Readings
# ==========================================
def insert_indoor_reading(device_id: str, temperature: float, humidity: float, timestamp: Optional[str] = None) -> int:
    conn = get_connection()
    if not timestamp:
        timestamp = datetime.now(timezone.utc).isoformat()
    with conn:
        cur = conn.execute("""
            INSERT INTO indoor_readings (device_id, temperature, humidity, timestamp)
            VALUES (?, ?, ?, ?)
        """, (device_id, round(temperature, 1), round(humidity, 1), timestamp))
        return cur.lastrowid


def get_latest_indoor_reading() -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.execute("""
        SELECT * FROM indoor_readings ORDER BY id DESC LIMIT 1
    """)
    row = cur.fetchone()
    return dict(row) if row else None


def get_indoor_history(limit: int = 100) -> List[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.execute("""
        SELECT * FROM indoor_readings ORDER BY id DESC LIMIT ?
    """, (limit,))
    rows = cur.fetchall()
    return [dict(r) for r in reversed(rows)]


# ==========================================
# Outdoor Readings
# ==========================================
def insert_outdoor_reading(
    city: str,
    latitude: float,
    longitude: float,
    temperature: float,
    humidity: float,
    wind_speed: float,
    weather_code: int,
    weather_desc: str,
    timestamp: Optional[str] = None
) -> int:
    conn = get_connection()
    if not timestamp:
        timestamp = datetime.now(timezone.utc).isoformat()
    with conn:
        cur = conn.execute("""
            INSERT INTO outdoor_readings (
                city, latitude, longitude, temperature, humidity,
                wind_speed, weather_code, weather_desc, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (city, latitude, longitude, round(temperature, 1), round(humidity, 1),
              round(wind_speed, 1), weather_code, weather_desc, timestamp))
        return cur.lastrowid


def get_latest_outdoor_reading() -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.execute("""
        SELECT * FROM outdoor_readings ORDER BY id DESC LIMIT 1
    """)
    row = cur.fetchone()
    return dict(row) if row else None


# ==========================================
# Alerts
# ==========================================
def insert_alert(
    source: str,
    parameter: str,
    triggered_value: float,
    threshold_value: float,
    alert_type: str,
    message: str
) -> int:
    conn = get_connection()
    now_str = datetime.now(timezone.utc).isoformat()
    with conn:
        cur = conn.execute("""
            INSERT INTO alert_logs (
                source, parameter, triggered_value, threshold_value,
                alert_type, message, timestamp, is_acknowledged
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 0)
        """, (source, parameter, triggered_value, threshold_value, alert_type, message, now_str))
        return cur.lastrowid


def get_alerts(limit: int = 50, only_unacknowledged: bool = False) -> List[Dict[str, Any]]:
    conn = get_connection()
    if only_unacknowledged:
        cur = conn.execute("""
            SELECT * FROM alert_logs WHERE is_acknowledged = 0 ORDER BY id DESC LIMIT ?
        """, (limit,))
    else:
        cur = conn.execute("""
            SELECT * FROM alert_logs ORDER BY id DESC LIMIT ?
        """, (limit,))
    rows = cur.fetchall()
    return [dict(r) for r in rows]


def acknowledge_alert(alert_id: int) -> bool:
    conn = get_connection()
    with conn:
        cur = conn.execute("""
            UPDATE alert_logs SET is_acknowledged = 1 WHERE id = ?
        """, (alert_id,))
        return cur.rowcount > 0


# ==========================================
# Thresholds
# ==========================================
def get_thresholds() -> Dict[str, Dict[str, Any]]:
    conn = get_connection()
    cur = conn.execute("SELECT * FROM threshold_configs")
    rows = cur.fetchall()
    return {r["parameter"]: dict(r) for r in rows}


def update_threshold(parameter: str, min_val: float, max_val: float, is_enabled: bool = True) -> bool:
    conn = get_connection()
    now_str = datetime.now(timezone.utc).isoformat()
    with conn:
        cur = conn.execute("""
            INSERT INTO threshold_configs (parameter, min_value, max_value, is_enabled, updated_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(parameter) DO UPDATE SET
                min_value = excluded.min_value,
                max_value = excluded.max_value,
                is_enabled = excluded.is_enabled,
                updated_at = excluded.updated_at
        """, (parameter, min_val, max_val, 1 if is_enabled else 0, now_str))
        return cur.rowcount > 0


# ==========================================
# Historical Combined Query
# ==========================================
def get_combined_history(limit: int = 50) -> List[Dict[str, Any]]:
    """Retrieve aligned historical data points for indoor and outdoor conditions."""
    conn = get_connection()
    # Fetch recent indoor readings
    cur = conn.execute("""
        SELECT timestamp, temperature, humidity FROM indoor_readings
        ORDER BY id DESC LIMIT ?
    """, (limit,))
    indoor_rows = list(reversed(cur.fetchall()))

    # Fetch recent outdoor readings
    cur_out = conn.execute("""
        SELECT timestamp, temperature, humidity FROM outdoor_readings
        ORDER BY id DESC LIMIT ?
    """, (limit,))
    outdoor_rows = list(reversed(cur_out.fetchall()))

    # Pair them or provide merged list
    points = []
    # If we have indoor points, build around them
    if indoor_rows:
        latest_out = outdoor_rows[-1] if outdoor_rows else None
        for r in indoor_rows:
            points.append({
                "timestamp": r["timestamp"],
                "indoor_temperature": r["temperature"],
                "indoor_humidity": r["humidity"],
                "outdoor_temperature": latest_out["temperature"] if latest_out else None,
                "outdoor_humidity": latest_out["humidity"] if latest_out else None
            })
    elif outdoor_rows:
        for r in outdoor_rows:
            points.append({
                "timestamp": r["timestamp"],
                "indoor_temperature": None,
                "indoor_humidity": None,
                "outdoor_temperature": r["temperature"],
                "outdoor_humidity": r["humidity"]
            })

    return points
