# Environmental Monitoring Platform - UI Redesign Guide

This folder contains the current Flutter UI screens and state provider for the **Integrated Environmental Monitoring Platform**.

---

## Files in this `input` folder:
1. `dashboard_screen.dart` - Main home dashboard displaying real-time metrics, comfort score, and status cards.
2. `charts_screen.dart` - Dual-trace comparative charts (indoor ESP32 vs outdoor weather).
3. `alerts_screen.dart` - Threshold and microclimate alerts.
4. `environment_provider.dart` - Provider holding all live sensor and cloud data.

---

## Available Data via `Provider.of<EnvironmentProvider>(context)`:
* **Indoor Metrics (ESP32 Sensor):**
  - `env.indoor?.temperature` (double, in °C)
  - `env.indoor?.humidity` (double, in %)
  - `env.indoor?.heatIndex` (double, in °C)
  - `env.indoorStatus` (String: "Online" / "Offline")
  - `env.indoor?.timestamp` (DateTime)
* **Outdoor Weather (Open-Meteo):**
  - `env.outdoor?.temperature` (double, in °C)
  - `env.outdoor?.humidity` (double, in %)
  - `env.outdoor?.windSpeed` (double, in km/h)
  - `env.outdoor?.weatherDescription` (String)
* **Comfort & Analytics:**
  - `env.comfortScore` (String: "Optimal", "Acceptable", "Discomfort")
  - `env.comfortAdvice` (String)
  - `env.temperatureDifference` (double: indoor - outdoor)
* **Historical Chart Data:**
  - `env.hourlyHistory` (List of ChartPoint: `point.timeLabel`, `point.indoorTemp`, `point.outdoorTemp`, etc.)
* **User & Auth:**
  - `env.isLoggedIn` (bool)
  - `env.currentUser` (String)
  - `env.isGuest` (bool)

---

## How to deliver your redesigned files:
1. Redesign the screen(s) based on your target reference image / design.
2. Save your new `.dart` files (and/or reference screenshot image) inside the `output/` folder.
3. Antigravity will automatically check, bind providers, compile, and integrate it into the live app.
