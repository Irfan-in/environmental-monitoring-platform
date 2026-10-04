import os
from pathlib import Path

# Base directory of the backend project
BASE_DIR = Path(__file__).resolve().parent.parent

# Database configuration
DATA_DIR = BASE_DIR / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)
DATABASE_FILE = DATA_DIR / "environmental_monitoring.db"

# Server configuration
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8080"))

# Outdoor Weather Location Settings (Default: Periya, Kerala)
DEFAULT_LATITUDE = float(os.getenv("WEATHER_LAT", "12.3980"))
DEFAULT_LONGITUDE = float(os.getenv("WEATHER_LON", "75.0945"))
DEFAULT_CITY = os.getenv("WEATHER_CITY", "Periya, Kerala")

# Weather auto-sync interval in seconds (default: 15 minutes = 900s)
WEATHER_SYNC_INTERVAL_SEC = int(os.getenv("WEATHER_SYNC_INTERVAL", "900"))

# Default Alert Thresholds
DEFAULT_TEMP_MIN = 18.0   # °C
DEFAULT_TEMP_MAX = 32.0   # °C
DEFAULT_HUM_MIN  = 30.0   # %
DEFAULT_HUM_MAX  = 70.0   # %
