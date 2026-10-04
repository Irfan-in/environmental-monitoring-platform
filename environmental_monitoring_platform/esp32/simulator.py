#!/usr/bin/env python3
"""
Integrated Environmental Monitoring Platform
ESP32 Hardware Simulator & Presentation Emulator

Author: Mohammed Irfan KS
Program: MCA (3rd Semester)

Description:
Simulates an ESP32 microcontroller with a DHT11/DHT22 sensor.
Transmits JSON sensor packets to the FastAPI backend via HTTP POST.
Allows demonstrating the platform to professors and reviewers without
physical microcontrollers plugged in.
"""

import sys
import time
import json
import random
import argparse
import urllib.request
import urllib.error
from datetime import datetime

# ANSI Color formatting for terminal presentation
GREEN  = "\033[92m"
BLUE   = "\033[94m"
YELLOW = "\033[93m"
RED    = "\033[91m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"


def print_banner():
    print(f"{CYAN}{BOLD}")
    print("=" * 64)
    print("      ESP32 SENSOR NODE SIMULATOR & DEMO EMULATOR      ")
    print("     Integrated Environmental Monitoring Platform      ")
    print("=" * 64 + f"{RESET}\n")


def send_packet(url: str, device_id: str, temperature: float, humidity: float):
    payload = {
        "device_id": device_id,
        "temperature": round(temperature, 1),
        "humidity": round(humidity, 1)
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json", "User-Agent": "ESP32-Simulator/1.0"}
    )

    now = datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] {BLUE}[TX -> POST]{RESET} Device: {BOLD}{device_id}{RESET} | "
          f"Temp: {YELLOW}{payload['temperature']}°C{RESET} | "
          f"Humidity: {CYAN}{payload['humidity']}%{RESET}")

    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            status_code = response.getcode()
            resp_body = response.read().decode("utf-8")
            resp_json = json.loads(resp_body) if resp_body else {}
            
            # Highlight if alerts were triggered
            alerts_triggered = resp_json.get("alerts_triggered", [])
            alert_str = ""
            if alerts_triggered:
                alert_str = f" | {RED}{BOLD}ALERT TRIGGERED: {alerts_triggered}{RESET}"

            print(f"       {GREEN}✓ [RX <- {status_code} OK]{RESET} Backend stored reading #{resp_json.get('reading_id', '?')}{alert_str}")
            return True
    except urllib.error.HTTPError as e:
        print(f"       {RED}✗ [RX <- HTTP {e.code}]{RESET} {e.reason}")
        return False
    except urllib.error.URLError as e:
        print(f"       {RED}✗ [Connection Error]{RESET} Backend unreachable at {url}. (Is the server running?)")
        return False
    except Exception as e:
        print(f"       {RED}✗ [Error]{RESET} {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="ESP32 IoT Sensor Simulator")
    parser.add_argument("--url", default="http://127.0.0.1:8080/api/indoor/reading",
                        help="Backend ingestion URL (default: http://127.0.0.1:8080/api/indoor/reading)")
    parser.add_argument("--device", default="esp32_room_node",
                        help="Device identifier string (default: esp32_room_node)")
    parser.add_argument("--interval", type=float, default=3.0,
                        help="Interval in seconds between transmissions (default: 3.0)")
    parser.add_argument("--mode", choices=["normal", "high-temp", "high-humidity", "cold", "fluctuate"],
                        default="normal",
                        help="Simulation scenario (normal, high-temp, high-humidity, cold, fluctuate)")
    parser.add_argument("--count", type=int, default=0,
                        help="Number of packets to send (0 for infinite loop, default: 0)")

    args = parser.parse_args()

    print_banner()
    print(f"Target URL   : {BOLD}{args.url}{RESET}")
    print(f"Device ID    : {BOLD}{args.device}{RESET}")
    print(f"Interval     : {BOLD}{args.interval}s{RESET}")
    print(f"Active Mode  : {BOLD}{args.mode.upper()}{RESET}")
    print(f"Exit         : Press {BOLD}Ctrl+C{RESET} to stop at any time.\n")
    print("-" * 64)

    # Initial baseline values
    if args.mode == "high-temp":
        temp = 34.0
        hum = 50.0
    elif args.mode == "high-humidity":
        temp = 25.0
        hum = 78.0
    elif args.mode == "cold":
        temp = 16.0
        hum = 45.0
    else:
        temp = 24.5
        hum = 55.0

    sent_count = 0
    try:
        while True:
            # Add subtle realistic natural drift
            if args.mode == "normal":
                temp += random.uniform(-0.25, 0.25)
                temp = max(21.0, min(28.0, temp))
                hum += random.uniform(-0.6, 0.6)
                hum = max(40.0, min(65.0, hum))
            elif args.mode == "high-temp":
                temp += random.uniform(-0.1, 0.3)
                temp = max(33.0, min(38.0, temp))
                hum += random.uniform(-0.5, 0.5)
            elif args.mode == "high-humidity":
                temp += random.uniform(-0.2, 0.2)
                hum += random.uniform(-0.2, 0.5)
                hum = max(72.0, min(92.0, hum))
            elif args.mode == "cold":
                temp += random.uniform(-0.3, 0.1)
                temp = max(12.0, min(17.5, temp))
            elif args.mode == "fluctuate":
                temp = 20.0 + 15.0 * (0.5 + 0.5 * (random.random()))
                hum = 30.0 + 50.0 * (random.random())

            send_packet(args.url, args.device, temp, hum)
            sent_count += 1

            if args.count > 0 and sent_count >= args.count:
                print(f"\n{GREEN}Completed sending {sent_count} packets.{RESET}")
                break

            time.sleep(args.interval)

    except KeyboardInterrupt:
        print(f"\n\n{YELLOW}Simulator stopped by user. Total packets sent: {sent_count}{RESET}")


if __name__ == "__main__":
    main()
