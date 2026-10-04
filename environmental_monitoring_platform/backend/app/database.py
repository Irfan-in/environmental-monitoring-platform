import sqlite3
import threading
from datetime import datetime, timezone
from app.config import (
    DATABASE_FILE,
    DEFAULT_TEMP_MIN,
    DEFAULT_TEMP_MAX,
    DEFAULT_HUM_MIN,
    DEFAULT_HUM_MAX
)

# Thread-local storage for SQLite connections
_local = threading.local()

def get_connection() -> sqlite3.Connection:
    """Get a thread-local SQLite connection with dictionary row factory."""
    if not hasattr(_local, "connection") or _local.connection is None:
        conn = sqlite3.connect(DATABASE_FILE, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL;")  # Better concurrency
        _local.connection = conn
    return _local.connection

def init_db():
    """Create tables and seed initial threshold defaults if not already present."""
    conn = get_connection()
    with conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS indoor_readings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT NOT NULL,
                temperature REAL NOT NULL,
                humidity REAL NOT NULL,
                timestamp TEXT NOT NULL
            );
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_indoor_ts ON indoor_readings(timestamp);")

        conn.execute("""
            CREATE TABLE IF NOT EXISTS outdoor_readings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                city TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                temperature REAL NOT NULL,
                humidity REAL NOT NULL,
                wind_speed REAL NOT NULL,
                weather_code INTEGER NOT NULL,
                weather_desc TEXT NOT NULL,
                timestamp TEXT NOT NULL
            );
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_outdoor_ts ON outdoor_readings(timestamp);")

        conn.execute("""
            CREATE TABLE IF NOT EXISTS alert_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                source TEXT NOT NULL,
                parameter TEXT NOT NULL,
                triggered_value REAL NOT NULL,
                threshold_value REAL NOT NULL,
                alert_type TEXT NOT NULL,
                message TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                is_acknowledged INTEGER DEFAULT 0
            );
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_alert_ts ON alert_logs(timestamp);")

        conn.execute("""
            CREATE TABLE IF NOT EXISTS threshold_configs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                parameter TEXT UNIQUE NOT NULL,
                min_value REAL NOT NULL,
                max_value REAL NOT NULL,
                is_enabled INTEGER DEFAULT 1,
                updated_at TEXT NOT NULL
            );
        """)

        # Seed default thresholds if empty
        cur = conn.execute("SELECT COUNT(*) FROM threshold_configs")
        if cur.fetchone()[0] == 0:
            now_str = datetime.now(timezone.utc).isoformat()
            conn.execute("""
                INSERT INTO threshold_configs (parameter, min_value, max_value, is_enabled, updated_at)
                VALUES ('temperature', ?, ?, 1, ?),
                       ('humidity', ?, ?, 1, ?)
            """, (DEFAULT_TEMP_MIN, DEFAULT_TEMP_MAX, now_str,
                  DEFAULT_HUM_MIN, DEFAULT_HUM_MAX, now_str))
