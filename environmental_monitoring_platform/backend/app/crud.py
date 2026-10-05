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
    if not row:
        return None
    data = dict(row)
    data["is_cached"] = "(Cached)" in data.get("weather_desc", "")
    cur_c = conn.execute("SELECT cached_at FROM outdoor_forecast_cache ORDER BY id DESC LIMIT 1")
    row_c = cur_c.fetchone()
    data["cached_at"] = row_c["cached_at"] if row_c else data.get("timestamp")
    return data


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
    """, (limit * 2,))
    outdoor_rows = list(reversed(cur_out.fetchall()))

    # Fetch 24h cached forecast as fallback for outdoor diurnal curve
    cur_f = conn.execute("""
        SELECT hour_timestamp as timestamp, temperature, humidity FROM outdoor_forecast_cache
        ORDER BY hour_timestamp ASC LIMIT 24
    """)
    forecast_rows = cur_f.fetchall()

    points = []
    if indoor_rows:
        for r in indoor_rows:
            in_ts = r["timestamp"]
            # Find closest outdoor reading by timestamp prefix (YYYY-MM-DDTHH)
            matched_out = None
            in_hour = in_ts[:13] if len(in_ts) >= 13 else in_ts
            for o in outdoor_rows:
                if o["timestamp"].startswith(in_hour):
                    matched_out = o
                    break
            if not matched_out and forecast_rows:
                for f in forecast_rows:
                    if f["timestamp"].startswith(in_hour):
                        matched_out = f
                        break
            if not matched_out and outdoor_rows:
                matched_out = outdoor_rows[-1]

            points.append({
                "timestamp": in_ts,
                "indoor_temperature": r["temperature"],
                "indoor_humidity": r["humidity"],
                "outdoor_temperature": matched_out["temperature"] if matched_out else None,
                "outdoor_humidity": matched_out["humidity"] if matched_out else None
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
    elif forecast_rows:
        for f in forecast_rows:
            points.append({
                "timestamp": f["timestamp"],
                "indoor_temperature": None,
                "indoor_humidity": None,
                "outdoor_temperature": f["temperature"],
                "outdoor_humidity": f["humidity"]
            })

    return points


# ==========================================
# Outdoor 24-Hour Forecast Cache
# ==========================================
def upsert_forecast_cache(
    city: str,
    hour_timestamp: str,
    temperature: float,
    humidity: float,
    weather_code: int,
    weather_desc: str,
    cached_at: str
) -> bool:
    """Store or update hourly forecast in SQLite cache."""
    conn = get_connection()
    with conn:
        cur = conn.execute("""
            INSERT INTO outdoor_forecast_cache (
                city, hour_timestamp, temperature, humidity,
                weather_code, weather_desc, cached_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(city, hour_timestamp) DO UPDATE SET
                temperature = excluded.temperature,
                humidity = excluded.humidity,
                weather_code = excluded.weather_code,
                weather_desc = excluded.weather_desc,
                cached_at = excluded.cached_at
        """, (city, hour_timestamp, round(temperature, 1), round(humidity, 1),
              weather_code, weather_desc, cached_at))
        return cur.rowcount > 0


def get_cached_forecast_for_time(city: str, target_iso: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """
    Retrieve the closest forecast reading for the given hour timestamp.
    Defaults to current UTC hour.
    """
    conn = get_connection()
    if not target_iso:
        target_iso = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:00")
    else:
        # Normalize to hour format: YYYY-MM-DDTHH:00
        target_iso = target_iso[:13] + ":00"

    # Exact match first
    cur = conn.execute("""
        SELECT * FROM outdoor_forecast_cache
        WHERE city = ? AND hour_timestamp LIKE ?
        LIMIT 1
    """, (city, f"{target_iso}%"))
    row = cur.fetchone()
    if row:
        return dict(row)

    # Fallback to the latest cached entry for this city
    cur2 = conn.execute("""
        SELECT * FROM outdoor_forecast_cache
        WHERE city = ?
        ORDER BY hour_timestamp DESC
        LIMIT 1
    """, (city,))
    row2 = cur2.fetchone()
    return dict(row2) if row2 else None


def get_24h_cached_forecast(city: str) -> List[Dict[str, Any]]:
    """Retrieve up to 24 cached hourly forecast points for diurnal comparison."""
    conn = get_connection()
    cur = conn.execute("""
        SELECT * FROM outdoor_forecast_cache
        WHERE city = ?
        ORDER BY hour_timestamp ASC
        LIMIT 24
    """, (city,))
    rows = cur.fetchall()
    return [dict(r) for r in rows]


# ==========================================
# User Authentication & Management
# ==========================================
def get_user_by_username(username: str) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cur = conn.execute("SELECT * FROM users WHERE username = ?", (username,))
    row = cur.fetchone()
    return dict(row) if row else None


def create_user(username: str, password_hash: str, role: str = "viewer") -> bool:
    conn = get_connection()
    now_str = datetime.now(timezone.utc).isoformat()
    try:
        with conn:
            cur = conn.execute("""
                INSERT INTO users (username, password_hash, role, created_at)
                VALUES (?, ?, ?, ?)
            """, (username, password_hash, role, now_str))
            return cur.rowcount > 0
    except Exception:
        return False


# ==========================================
# Cloud Backup & Restore
# ==========================================
def export_database_backup() -> Dict[str, Any]:
    """Export complete snapshot of readings, thresholds, and alerts."""
    conn = get_connection()
    indoor = [dict(r) for r in conn.execute("SELECT * FROM indoor_readings ORDER BY id ASC").fetchall()]
    outdoor = [dict(r) for r in conn.execute("SELECT * FROM outdoor_readings ORDER BY id ASC").fetchall()]
    alerts = [dict(r) for r in conn.execute("SELECT * FROM alert_logs ORDER BY id ASC").fetchall()]
    thresholds = [dict(r) for r in conn.execute("SELECT * FROM threshold_configs").fetchall()]
    return {
        "version": "1.0",
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "indoor_readings": indoor,
        "outdoor_readings": outdoor,
        "alert_logs": alerts,
        "threshold_configs": thresholds
    }


def import_database_backup(backup_data: Dict[str, Any]) -> Dict[str, int]:
    """Restore readings and configurations from backup payload."""
    conn = get_connection()
    restored = {"indoor": 0, "outdoor": 0, "thresholds": 0}
    with conn:
        for r in backup_data.get("indoor_readings", []):
            try:
                conn.execute("""
                    INSERT INTO indoor_readings (device_id, temperature, humidity, timestamp)
                    VALUES (?, ?, ?, ?)
                """, (r["device_id"], r["temperature"], r["humidity"], r["timestamp"]))
                restored["indoor"] += 1
            except Exception:
                pass

        for r in backup_data.get("outdoor_readings", []):
            try:
                conn.execute("""
                    INSERT INTO outdoor_readings (
                        city, latitude, longitude, temperature, humidity,
                        wind_speed, weather_code, weather_desc, timestamp
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (r["city"], r["latitude"], r["longitude"], r["temperature"],
                      r["humidity"], r["wind_speed"], r["weather_code"],
                      r["weather_desc"], r["timestamp"]))
                restored["outdoor"] += 1
            except Exception:
                pass

        for t in backup_data.get("threshold_configs", []):
            try:
                conn.execute("""
                    INSERT INTO threshold_configs (parameter, min_value, max_value, is_enabled, updated_at)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(parameter) DO UPDATE SET
                        min_value = excluded.min_value,
                        max_value = excluded.max_value,
                        is_enabled = excluded.is_enabled,
                        updated_at = excluded.updated_at
                """, (t["parameter"], t["min_value"], t["max_value"], t["is_enabled"], t["updated_at"]))
                restored["thresholds"] += 1
            except Exception:
                pass

    return restored
