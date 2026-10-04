import os
import threading
import time
from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from app.database import init_db
from app.routers import indoor, outdoor, comparison, history, alerts
from app.services.weather_service import fetch_open_meteo_weather
from app.config import WEATHER_SYNC_INTERVAL_SEC, BASE_DIR


def background_weather_sync():
    """Periodically fetch outdoor weather to keep database fresh."""
    while True:
        try:
            fetch_open_meteo_weather()
        except Exception as e:
            print(f"[Weather Sync] Error: {e}")
        time.sleep(WEATHER_SYNC_INTERVAL_SEC)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize Database
    init_db()
    print("[Backend] SQLite database initialized successfully.")

    # Fetch initial weather in background
    sync_thread = threading.Thread(target=background_weather_sync, daemon=True)
    sync_thread.start()
    print("[Backend] Outdoor weather sync background service started.")

    yield
    print("[Backend] Application shutting down.")


app = FastAPI(
    title="Integrated Environmental Monitoring Platform API",
    description="Backend API integrating indoor IoT ESP32 sensor telemetry with external weather API data.",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Flutter Web, Android emulators, and local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register Routers
app.include_router(indoor.router)
app.include_router(outdoor.router)
app.include_router(comparison.router)
app.include_router(history.router)
app.include_router(alerts.router)


# Health check
@app.get("/api/health", tags=["System"])
def health_check():
    return {"status": "online", "platform": "Integrated Environmental Monitoring Platform"}


# Mount static directory for instant web dashboard preview
static_dir = BASE_DIR / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

    @app.get("/", include_in_schema=False)
    def serve_dashboard():
        index_file = static_dir / "index.html"
        if index_file.exists():
            return FileResponse(index_file)
        return {"message": "Environmental Monitoring API is running. Visit /docs for Swagger UI."}
