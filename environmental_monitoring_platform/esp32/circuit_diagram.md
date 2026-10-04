# ESP32 + DHT11/DHT22 Circuit Diagram & Hardware Setup

This document provides complete instructions for wiring the **ESP32 Wi-Fi Development Board** to a **DHT11** or **DHT22** digital temperature and humidity sensor.

---

## 1. Components Required

| Component | Quantity | Description |
| :--- | :---: | :--- |
| **ESP32 Development Board** | 1 | 30-pin or 38-pin ESP-WROOM-32 DevKit |
| **DHT11 or DHT22 Sensor** | 1 | 3-pin module (built-in resistor) OR 4-pin bare sensor |
| **Resistor (10 kΩ)** | 1 | *Only required if using 4-pin bare sensor* (pull-up between VCC & DATA) |
| **Half-Size Breadboard** | 1 | For solderless prototyping |
| **Jumper Wires** | 3-4 | Male-to-Male or Male-to-Female |
| **Micro-USB Cable** | 1 | Data + Power connection to PC |

---

## 2. Pinout & Wiring Connections

### 3-Pin Sensor Module (Most Common)
Most maker modules have 3 pins labeled `+` (or `VCC`), `OUT` (or `DAT`), and `-` (or `GND`).

```
ESP32 DevKit                  DHT Module (3-Pin)
+-----------------------+     +-----------------------+
| 3V3 (or VIN 5V)       |---->| VCC (+)               |
| GND                   |---->| GND (-)               |
| GPIO 4 (D4)           |<----| DATA (OUT / S)        |
+-----------------------+     +-----------------------+
```

### 4-Pin Bare DHT Sensor
If using a 4-pin raw sensor:
```
Pin 1 (Leftmost): VCC    --> ESP32 3.3V
Pin 2:            DATA   --> ESP32 GPIO 4 (also connect 10k resistor to Pin 1 VCC)
Pin 3:            NC     --> Not Connected
Pin 4 (Rightmost): GND   --> ESP32 GND
```

---

## 3. Visual Breadboard Schematic (ASCII)

```
        +-----------------------+
        |     ESP32 DEVKIT      |
        |                       |
        | [3V3]             [G] |  (G = GND)
        |  |                 |  |
        | [D4] (GPIO 4)      |  |
        +--|-----------------|--+
           |                 |
           |    +------------+
           |    |
           v    v
       +---------------+
       |   DHT SENSOR  |
       |               |
       |  [+] [OUT] [-]|
       +---------------+
           ^    ^    ^
           |    |    |
   3V3 ----+    |    +---- GND
   GPIO 4 ------+
```

---

## 4. Hardware Verification & Troubleshooting

1. **LED Status Indicators**:
   - Flashing rapidly: ESP32 is attempting to connect to Wi-Fi.
   - Solid ON: ESP32 is connected to Wi-Fi.
   - Double-blink: Sensor packet successfully transmitted to backend (`HTTP 200 OK`).

2. **Sensor Readings NaN ("Failed to read from DHT sensor")**:
   - Check if the DHT VCC is connected to `3V3`. Some older DHT11 modules require `VIN` (5V).
   - Ensure the data wire is firmly inserted into GPIO pin 4 (marked `D4` or `IO4` on most boards).
   - In `esp32_sensor_node.ino`, verify you selected `#define DHTTYPE DHT11` or `#define DHTTYPE DHT22` matching your physical sensor.

3. **Backend Connection Refused**:
   - Ensure your computer running the FastAPI backend is on the **same Wi-Fi network / hotspot** as the ESP32.
   - Update `SERVER_URL` in `esp32_sensor_node.ino` with your computer's local IP (find it using `ip route` or `ipconfig`).
