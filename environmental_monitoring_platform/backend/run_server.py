#!/usr/bin/env python3
"""
Integrated Environmental Monitoring Platform - Universal Server Runner

Author: Mohammed Irfan KS
Program: MCA (3rd Semester)

Description:
Runs the backend server.
1. If FastAPI & Uvicorn are installed, launches the full ASGI FastAPI production server.
2. If FastAPI is not yet installed in the current environment, automatically activates
   the built-in Python Standard Library server with 100% endpoint compatibility,
   allowing instant demonstration to professors without package installation delays.
"""

import sys
import os
from pathlib import Path

# Add current directory to python path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

def run_fastapi_server(host="0.0.0.0", port=8080):
    import uvicorn
    print(f"\n=======================================================")
    print(f"  [FastAPI Engine] Starting ASGI Server at http://{host}:{port}")
    print(f"  Interactive Docs (Swagger) : http://localhost:{port}/docs")
    print(f"  Interactive Dashboard UI   : http://localhost:{port}/")
    print(f"=======================================================\n")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)


def run_builtin_server(host="0.0.0.0", port=8080):
    """Fallback standard-library server implementing identical REST API & Dashboard."""
    import json
    import sqlite3
    import urllib.parse
    from http.server import HTTPServer, SimpleHTTPRequestHandler
    from app.database import init_db, get_connection
    from app.services.alert_service import evaluate_indoor_thresholds
    from app.services.weather_service import fetch_open_meteo_weather
    from app.crud import (
        insert_indoor_reading,
        get_latest_indoor_reading,
        get_indoor_history,
        get_latest_outdoor_reading,
        get_alerts,
        acknowledge_alert,
        get_thresholds,
        update_threshold,
        get_combined_history,
        get_user_by_username,
        create_user,
        export_database_backup,
        import_database_backup
    )
    import hashlib
    from app.services.metrics import compute_heat_index, evaluate_comfort

    # Initialize SQLite database
    init_db()
    # Fetch initial outdoor weather
    fetch_open_meteo_weather()

    static_dir = BASE_DIR / "static"

    class RestHandler(SimpleHTTPRequestHandler):
        def _set_headers(self, status=200, content_type="application/json"):
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.end_headers()

        def do_OPTIONS(self):
            self._set_headers(200)

        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path
            query = urllib.parse.parse_qs(parsed.query)

            # Serve static files and index.html
            if path == "/" or path == "/index.html":
                self.send_response(200)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                with open(static_dir / "index.html", "rb") as f:
                    self.wfile.write(f.read())
                return
            elif path.startswith("/static/"):
                rel_path = path.replace("/static/", "")
                file_path = static_dir / rel_path
                if file_path.exists() and file_path.is_file():
                    ext = file_path.suffix.lower()
                    mime = "text/css" if ext == ".css" else "application/javascript" if ext == ".js" else "application/octet-stream"
                    self.send_response(200)
                    self.send_header("Content-Type", mime)
                    self.end_headers()
                    with open(file_path, "rb") as f:
                        self.wfile.write(f.read())
                    return
                else:
                    self._set_headers(404, "text/plain")
                    self.wfile.write(b"Not Found")
                    return

            # REST Endpoints
            if path == "/api/health":
                self._set_headers(200)
                self.wfile.write(json.dumps({"status": "online", "mode": "builtin_universal"}).encode("utf-8"))

            elif path == "/api/indoor/latest":
                reading = get_latest_indoor_reading()
                if reading:
                    self._set_headers(200)
                    self.wfile.write(json.dumps(reading).encode("utf-8"))
                else:
                    self._set_headers(404)
                    self.wfile.write(json.dumps({"detail": "No readings yet"}).encode("utf-8"))

            elif path == "/api/indoor/history":
                hist = get_indoor_history(limit=50)
                self._set_headers(200)
                self.wfile.write(json.dumps(hist).encode("utf-8"))

            elif path == "/api/outdoor/latest":
                reading = get_latest_outdoor_reading()
                if not reading:
                    fetch_open_meteo_weather()
                    reading = get_latest_outdoor_reading()
                self._set_headers(200)
                self.wfile.write(json.dumps(reading).encode("utf-8"))

            elif path == "/api/comparison":
                indoor = get_latest_indoor_reading()
                outdoor = get_latest_outdoor_reading()
                if not outdoor:
                    fetch_open_meteo_weather()
                    outdoor = get_latest_outdoor_reading()

                if not indoor or not outdoor:
                    resp = {
                        "indoor": indoor,
                        "outdoor": outdoor,
                        "temp_diff": None,
                        "hum_diff": None,
                        "indoor_heat_index": None,
                        "outdoor_heat_index": None,
                        "comfort_assessment": "Insufficient Data",
                        "status_summary": "Waiting for indoor and outdoor telemetry."
                    }
                else:
                    temp_diff = round(indoor["temperature"] - outdoor["temperature"], 1)
                    hum_diff = round(indoor["humidity"] - outdoor["humidity"], 1)
                    in_hi = compute_heat_index(indoor["temperature"], indoor["humidity"])
                    out_hi = compute_heat_index(outdoor["temperature"], outdoor["humidity"])

                    if 21.0 <= indoor["temperature"] <= 26.0 and 40.0 <= indoor["humidity"] <= 60.0:
                        comfort = "Ideal Comfort Zone (ASHRAE Standard 55)"
                    elif indoor["temperature"] > 28.0:
                        comfort = "Warm / Elevated Thermal Load"
                    elif indoor["temperature"] < 19.0:
                        comfort = "Cool / Below Neutral Zone"
                    elif indoor["humidity"] > 65.0:
                        comfort = "Humid / Potential Stuffiness"
                    elif indoor["humidity"] < 35.0:
                        comfort = "Dry Air / Respiratory Caution"
                    else:
                        comfort = "Acceptable Indoor Conditions"

                    summary = f"Indoor environment is {abs(temp_diff):.1f}°C {'cooler' if temp_diff < 0 else 'warmer'} than outside." if abs(temp_diff) >= 1.0 else "Indoor and outdoor temperatures are balanced."

                    resp = {
                        "indoor": indoor,
                        "outdoor": outdoor,
                        "temp_diff": temp_diff,
                        "hum_diff": hum_diff,
                        "indoor_heat_index": in_hi,
                        "outdoor_heat_index": out_hi,
                        "comfort_assessment": comfort,
                        "status_summary": summary
                    }
                self._set_headers(200)
                self.wfile.write(json.dumps(resp).encode("utf-8"))

            elif path == "/api/history":
                raw = get_combined_history(limit=50)
                self._set_headers(200)
                self.wfile.write(json.dumps({"timeframe": "24h", "count": len(raw), "points": raw}).encode("utf-8"))

            elif path == "/api/alerts":
                unack = "unacknowledged_only" in query and query["unacknowledged_only"][0].lower() == "true"
                alerts = get_alerts(limit=50, only_unacknowledged=unack)
                self._set_headers(200)
                self.wfile.write(json.dumps(alerts).encode("utf-8"))

            elif path == "/api/alerts/thresholds":
                cfgs = get_thresholds()
                res = [{"parameter": p, "min_value": c["min_value"], "max_value": c["max_value"], "is_enabled": bool(c["is_enabled"])} for p, c in cfgs.items()]
                self._set_headers(200)
                self.wfile.write(json.dumps(res).encode("utf-8"))

            elif path == "/api/sync/backup":
                backup = export_database_backup()
                self._set_headers(200)
                self.wfile.write(json.dumps(backup).encode("utf-8"))

            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"detail": "Endpoint not found"}).encode("utf-8"))

        def do_POST(self):
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8") if content_length > 0 else "{}"
            try:
                data = json.loads(body)
            except Exception:
                data = {}

            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path

            if path == "/api/indoor/reading":
                dev = data.get("device_id", "esp32_default")
                temp = float(data.get("temperature", 25.0))
                hum = float(data.get("humidity", 50.0))
                rid = insert_indoor_reading(dev, temp, hum)
                alerts = evaluate_indoor_thresholds(dev, temp, hum)
                self._set_headers(200)
                self.wfile.write(json.dumps({"success": True, "reading_id": rid, "alerts_triggered": alerts}).encode("utf-8"))

            elif path == "/api/outdoor/sync":
                fetch_open_meteo_weather()
                reading = get_latest_outdoor_reading()
                self._set_headers(200)
                self.wfile.write(json.dumps(reading).encode("utf-8"))

            elif path.startswith("/api/alerts/") and path.endswith("/ack"):
                parts = path.strip("/").split("/")
                if len(parts) >= 3 and parts[2].isdigit():
                    aid = int(parts[2])
                    acknowledge_alert(aid)
                    self._set_headers(200)
                    self.wfile.write(json.dumps({"success": True, "alert_id": aid}).encode("utf-8"))
                    return
                self._set_headers(400)
                self.wfile.write(json.dumps({"detail": "Invalid alert id"}).encode("utf-8"))

            elif path == "/api/auth/login":
                u = data.get("username", "")
                p = data.get("password", "")
                user = get_user_by_username(u)
                if user and user["password_hash"] == hashlib.sha256(p.encode()).hexdigest():
                    self._set_headers(200)
                    self.wfile.write(json.dumps({
                        "success": True,
                        "username": user["username"],
                        "role": user["role"],
                        "token": f"token_{user['username']}_{user['role']}",
                        "message": f"Welcome back, {user['username']}! Logged in as {user['role'].capitalize()}."
                    }).encode("utf-8"))
                else:
                    self._set_headers(401)
                    self.wfile.write(json.dumps({"detail": "Invalid credentials"}).encode("utf-8"))

            elif path == "/api/auth/register":
                u = data.get("username", "")
                p = data.get("password", "")
                if not u or not p:
                    self._set_headers(400)
                    self.wfile.write(json.dumps({"detail": "Username and password required"}).encode("utf-8"))
                elif get_user_by_username(u):
                    self._set_headers(400)
                    self.wfile.write(json.dumps({"detail": "Username already exists"}).encode("utf-8"))
                else:
                    create_user(u, hashlib.sha256(p.encode()).hexdigest(), role="viewer")
                    self._set_headers(200)
                    self.wfile.write(json.dumps({"success": True, "message": "Registered successfully"}).encode("utf-8"))

            elif path == "/api/sync/restore":
                counts = import_database_backup(data)
                self._set_headers(200)
                self.wfile.write(json.dumps({"success": True, "message": "Restored successfully", "restored": counts}).encode("utf-8"))

            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"detail": "Endpoint not found"}).encode("utf-8"))

        def do_PUT(self):
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8") if content_length > 0 else "{}"
            try:
                data = json.loads(body)
            except Exception:
                data = {}

            path = urllib.parse.urlparse(self.path).path
            if path.startswith("/api/alerts/thresholds/"):
                param = path.split("/")[-1]
                min_v = float(data.get("min_value", 18.0))
                max_v = float(data.get("max_value", 32.0))
                enabled = bool(data.get("is_enabled", True))
                update_threshold(param, min_v, max_v, enabled)
                self._set_headers(200)
                self.wfile.write(json.dumps({"success": True, "parameter": param, "min_value": min_v, "max_value": max_v}).encode("utf-8"))
            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"detail": "Not found"}).encode("utf-8"))

    print(f"\n=======================================================")
    print(f"  [Universal Backend] Server running at http://{host}:{port}")
    print(f"  Live Interactive Web Dashboard: http://localhost:{port}/")
    print(f"=======================================================\n")
    server = HTTPServer((host, port), RestHandler)
    server.serve_forever()


if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))

    try:
        import fastapi
        import uvicorn
        run_fastapi_server(host, port)
    except ImportError:
        print("[Notice] Running in standard universal mode.")
        run_builtin_server(host, port)
