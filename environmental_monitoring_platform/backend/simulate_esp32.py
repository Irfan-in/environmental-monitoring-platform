#!/usr/bin/env python3
"""
ESP32 Hardware Sensing Node Simulator
Author: Mohammed Irfan KS (MCA 3rd Sem)

Simulates the physical ESP32 + DHT22 + SSD1306 OLED node:
- Generates realistic diurnal indoor temperature and humidity fluctuations.
- Renders an ASCII virtual OLED screen in the terminal.
- Posts live telemetry to http://localhost:8080/api/indoor/reading every 3 seconds.
"""

import time
import math
import random
import json
import urllib.request
import urllib.error
import sys

BACKEND_URL = "http://127.0.0.1:8080/api/indoor/reading"
DEVICE_ID = "esp32_simulated_node"

def render_virtual_oled(temp: float, hum: float, status: str, count: int):
    # Clears screen or prints formatted OLED display box
    oled = f"""
    +----------------------------------+
    |  [OLED 128x64] Mohd Irfan KS    |
    |  MCA 3rd Sem (ESP32 Simulated)   |
    +----------------------------------+
    |  Temp : {temp:5.1f} °C                 |
    |  Hum  : {hum:5.1f} %                  |
    +----------------------------------+
    |  Status: {status:<15}  #{count:<4} |
    +----------------------------------+
    """
    print(oled)

def main():
    print("==================================================")
    print("  ESP32 Hardware Node Simulation Starting...")
    print(f"  Target Backend: {BACKEND_URL}")
    print("  Press Ctrl+C to stop simulation.")
    print("==================================================")

    step = 0
    base_temp = 25.5
    base_hum = 55.0

    while True:
        step += 1
        # Realistic sensor fluctuations
        temp = round(base_temp + 2.0 * math.sin(step * 0.1) + random.uniform(-0.3, 0.3), 1)
        hum = round(base_hum + 5.0 * math.cos(step * 0.1) + random.uniform(-0.5, 0.5), 1)

        payload = {
            "device_id": DEVICE_ID,
            "temperature": temp,
            "humidity": hum
        }

        status = "Transmitting..."
        try:
            req = urllib.request.Request(
                BACKEND_URL,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=3) as resp:
                if resp.status == 200:
                    status = "HTTP 200 OK"
                else:
                    status = f"HTTP {resp.status}"
        except urllib.error.URLError as e:
            status = "Conn Offline"
        except Exception as e:
            status = "Error"

        render_virtual_oled(temp, hum, status, step)
        time.sleep(3)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[Simulator] Stopped by user.")
