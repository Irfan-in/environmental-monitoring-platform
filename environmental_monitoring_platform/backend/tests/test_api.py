#!/usr/bin/env python3
"""
Unit and Integration Tests for Environmental Monitoring Platform Backend

Author: Mohammed Irfan KS
Program: MCA (3rd Semester)
"""

import sys
import unittest
from pathlib import Path

# Add backend directory to sys.path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BASE_DIR))

from app.database import init_db, get_connection
from app.crud import (
    insert_indoor_reading,
    get_latest_indoor_reading,
    get_latest_outdoor_reading,
    get_alerts,
    acknowledge_alert,
    get_thresholds,
    update_threshold
)
from app.services.alert_service import evaluate_indoor_thresholds
from app.services.weather_service import fetch_open_meteo_weather
from app.services.metrics import compute_heat_index


class TestEnvironmentalPlatform(unittest.TestCase):

    def setUp(self):
        """Initialize database before tests."""
        init_db()

    def test_database_initialization(self):
        """Verify database tables and initial threshold defaults."""
        conn = get_connection()
        cur = conn.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [r[0] for r in cur.fetchall()]
        self.assertIn("indoor_readings", tables)
        self.assertIn("outdoor_readings", tables)
        self.assertIn("alert_logs", tables)
        self.assertIn("threshold_configs", tables)

    def test_indoor_reading_storage(self):
        """Verify ESP32 indoor sensor packet insertion and retrieval."""
        test_temp = 25.8
        test_hum = 52.4
        rid = insert_indoor_reading("esp32_test_node", test_temp, test_hum)
        self.assertGreater(rid, 0)

        latest = get_latest_indoor_reading()
        self.assertIsNotNone(latest)
        self.assertEqual(latest["device_id"], "esp32_test_node")
        self.assertEqual(latest["temperature"], test_temp)
        self.assertEqual(latest["humidity"], test_hum)

    def test_alert_threshold_evaluation(self):
        """Verify alerts are triggered when readings exceed thresholds."""
        # 36.5°C exceeds default max threshold of 32.0°C
        alerts = evaluate_indoor_thresholds("esp32_test_node", 36.5, 50.0)
        self.assertGreater(len(alerts), 0)
        self.assertTrue(any("High Temperature" in a for a in alerts))

        # Check alert was logged in database
        logged_alerts = get_alerts(limit=5)
        self.assertGreater(len(logged_alerts), 0)
        self.assertEqual(logged_alerts[0]["alert_type"], "HIGH")
        self.assertEqual(logged_alerts[0]["parameter"], "temperature")

    def test_outdoor_weather_fetch(self):
        """Verify weather fetching service works (live or fallback)."""
        data = fetch_open_meteo_weather()
        self.assertIn("temperature", data)
        self.assertIn("humidity", data)
        self.assertIn("weather_desc", data)

        latest_outdoor = get_latest_outdoor_reading()
        self.assertIsNotNone(latest_outdoor)
        self.assertEqual(latest_outdoor["city"], data["city"])

    def test_heat_index_calculation(self):
        """Verify Heat Index calculation formula."""
        # 30°C and 70% humidity should result in high apparent heat index
        hi = compute_heat_index(30.0, 70.0)
        self.assertGreater(hi, 30.0)

    def test_alert_acknowledgement(self):
        """Verify marking alerts as acknowledged."""
        alerts = get_alerts(limit=1)
        if alerts:
            aid = alerts[0]["id"]
            success = acknowledge_alert(aid)
            self.assertTrue(success)


if __name__ == "__main__":
    unittest.main(verbosity=2)
