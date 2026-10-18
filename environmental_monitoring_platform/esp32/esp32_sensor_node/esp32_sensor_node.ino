/*
 * ==============================================================================
 * Integrated Environmental Monitoring Platform - Dual-Mode Hardware Sensing Node
 * ==============================================================================
 * Author : Mohammed Irfan KS
 * Roll No: KCMIT25MCA-2011
 * Program: MCA (3rd Semester)
 *
 * Hardware Configuration:
 *   - ESP32 Development Board
 *   - DHT22 Temperature & Humidity Sensor (Data: GPIO 4)
 *   - 0.96-inch I2C OLED Display SSD1306 (SDA: GPIO 21, SCL: GPIO 22)
 *
 * Dual Connectivity Strategy:
 *   1. SHORT RANGE (Bluetooth Serial "ESP32_ENV_MONITOR"):
 *      - Direct peer-to-peer connection with phone app.
 *      - Direct low-latency sensor streaming (0ms delay).
 *      - Hardware control & dynamic Wi-Fi provisioning (SSID/Password).
 *   2. LONG RANGE (Wi-Fi STA + HTTP Client):
 *      - Connects to Wi-Fi exclusively for background data synchronization.
 *      - Uploads telemetry to Central Backend Server (POST /api/indoor/reading).
 *      - Enables remote monitoring on the app even when far away.
 * ==============================================================================
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include "BluetoothSerial.h"
#include <Preferences.h>

// ==============================================================================
// 1. Dual-Connectivity Objects & Settings
// ==============================================================================
BluetoothSerial SerialBT;
Preferences preferences;

// Dynamic Wi-Fi credentials stored in flash NVS
String wifi_ssid     = "Irfan";
String wifi_password = "password123";
String device_id     = "esp32_node_01";
unsigned long post_interval_ms = 3000;
bool oled_enabled    = true;

// ==============================================================================
// 2. Hardware Pinout
// ==============================================================================
#define DHTPIN        4       // GPIO 4 for DHT22 Data
#define DHTTYPE       DHT22   // AM2302 / DHT22 Sensor
#define SCREEN_WIDTH  128     // OLED width
#define SCREEN_HEIGHT 64      // OLED height
#define OLED_RESET    -1
#define SCREEN_ADDR   0x3C    // I2C address for 0.96" SSD1306

DHT dht(DHTPIN, DHTTYPE);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

unsigned long lastPostTime = 0;
String statusLine = "Init...";

// ==============================================================================
// OLED Display Helper
// ==============================================================================
void updateOled(float temp, float hum, String status) {
  if (!oled_enabled) {
    display.clearDisplay();
    display.display();
    return;
  }

  display.clearDisplay();
  
  // Header with Connection Mode
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  if (SerialBT.hasClient()) {
    display.print("ENV [BT LINK ACTIVE]");
  } else if (WiFi.status() == WL_CONNECTED) {
    display.print("ENV [WIFI CLOUD]");
  } else {
    display.print("ENV [OFFLINE STANDBY]");
  }
  display.drawLine(0, 9, 127, 9, SSD1306_WHITE);

  // Temperature
  display.setCursor(0, 14);
  display.print("Temp: ");
  display.setTextSize(2);
  display.print(temp, 1);
  display.setTextSize(1);
  display.print(" C");

  // Humidity
  display.setCursor(0, 34);
  display.print("Hum:  ");
  display.setTextSize(2);
  display.print(hum, 1);
  display.setTextSize(1);
  display.print(" %");

  // Status Footer
  display.drawLine(0, 52, 127, 52, SSD1306_WHITE);
  display.setCursor(0, 55);
  display.print(status);

  display.display();
}

// ==============================================================================
// Wi-Fi Connection Routine
// ==============================================================================
void connectToWiFi() {
  if (wifi_ssid.length() == 0) return;

  Serial.println("[WiFi] Connecting to: " + wifi_ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifi_ssid.c_str(), wifi_password.c_str());

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 15) {
    delay(400);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected successfully!");
    Serial.print("[WiFi] ESP32 IP: ");
    Serial.println(WiFi.localIP());
    statusLine = "WiFi: " + WiFi.localIP().toString();
  } else {
    Serial.println("\n[WiFi] Connection failed. Using Bluetooth fallback.");
    statusLine = "WiFi Standby (Use BT)";
  }
}

// ==============================================================================
// HTTP Data Upload to Server (Long Range Sync)
// ==============================================================================
void uploadToServer(float temp, float hum) {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  // 1. Primary Target: 24/7 Render Cloud Backend (HTTPS)
  String serverUrl = "https://environmental-monitoring-backend.onrender.com/api/indoor/reading";

  #if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
  #else
    StaticJsonDocument<256> doc;
  #endif

  doc["device_id"]   = device_id;
  doc["temperature"] = serialized(String(temp, 1));
  doc["humidity"]    = serialized(String(hum, 1));

  String payload;
  serializeJson(doc, payload);

  WiFiClientSecure client;
  client.setInsecure(); // Disable certificate validation on ESP32

  HTTPClient http;
  http.begin(client, serverUrl);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(4000);

  int httpCode = http.POST(payload);
  if (httpCode == 200 || httpCode == 201) {
    statusLine = "Cloud Sync OK [200]";
  } else {
    // 2. Fallback Target: Local Gateway on port 8080
    http.end();
    String localUrl = "http://" + WiFi.gatewayIP().toString() + ":8080/api/indoor/reading";
    HTTPClient localHttp;
    localHttp.begin(localUrl);
    localHttp.addHeader("Content-Type", "application/json");
    localHttp.setTimeout(2000);
    httpCode = localHttp.POST(payload);
    if (httpCode == 200 || httpCode == 201) {
      statusLine = "Local Sync OK [200]";
    } else {
      statusLine = "Sync Code: " + String(httpCode);
    }
    localHttp.end();
    return;
  }
  http.end();
}

// ==============================================================================
// Bluetooth Command Processor (Direct Hardware Control & Wi-Fi Provisioning)
// ==============================================================================
void handleBluetoothCommands() {
  if (!SerialBT.available()) return;

  String line = SerialBT.readStringUntil('\n');
  line.trim();
  if (line.length() == 0) return;

  Serial.println("[BT CMD] Received: " + line);

  #if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
  #else
    StaticJsonDocument<512> doc;
  #endif

  DeserializationError err = deserializeJson(doc, line);
  if (err) {
    SerialBT.println("{\"error\":\"Invalid JSON\"}");
    return;
  }

  const char* cmd = doc["cmd"] | "";

  // 1. Wi-Fi Provisioning via Bluetooth
  if (strcmp(cmd, "set_wifi") == 0) {
    const char* new_ssid = doc["ssid"] | "";
    const char* new_pass = doc["pass"] | "";

    wifi_ssid = String(new_ssid);
    wifi_password = String(new_pass);

    // Save permanently to NVS
    preferences.putString("ssid", wifi_ssid);
    preferences.putString("pass", wifi_password);

    SerialBT.println("{\"status\":\"ok\",\"message\":\"WiFi credentials updated. Reconnecting...\"}");
    connectToWiFi();
  }
  // 2. Hardware Sampling Rate Adjustment
  else if (strcmp(cmd, "set_interval") == 0) {
    int interval = doc["val"] | 3000;
    post_interval_ms = (unsigned long)interval;
    preferences.putInt("interval", interval);
    SerialBT.println("{\"status\":\"ok\",\"message\":\"Sampling interval updated\"}");
  }
  // 3. OLED Display Power Toggle
  else if (strcmp(cmd, "set_oled") == 0) {
    oled_enabled = doc["val"] | true;
    SerialBT.println("{\"status\":\"ok\",\"message\":\"OLED power updated\"}");
  }
  // 4. Ping / Status Request
  else if (strcmp(cmd, "ping") == 0) {
    SerialBT.println("{\"status\":\"pong\",\"device\":\"ESP32_ENV_MONITOR\",\"wifi\":true}");
  }
}

// ==============================================================================
// Setup
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  // Initialize NVS Preferences
  preferences.begin("env_config", false);
  wifi_ssid     = preferences.getString("ssid", "Irfan");
  wifi_password = preferences.getString("pass", "password123");
  post_interval_ms = (unsigned long)preferences.getInt("interval", 3000);

  // 1. Initialize Bluetooth Serial (Primary Direct Link)
  SerialBT.begin("ESP32_ENV_MONITOR");
  Serial.println("[Bluetooth] Initialized as 'ESP32_ENV_MONITOR'");

  // 2. Initialize OLED Display (SDA=21, SCL=22)
  Wire.begin(21, 22);
  if (display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDR)) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("ESP32 Dual-Mode Node");
    display.println("BT: ESP32_ENV_MONITOR");
    display.println("Connecting WiFi...");
    display.display();
  }

  // 3. Initialize DHT22
  dht.begin();
  Serial.println("[DHT22] Initialized on GPIO 4");

  // 4. Connect to Wi-Fi for Long-Range Sync
  connectToWiFi();
}

// ==============================================================================
// Main Loop
// ==============================================================================
void loop() {
  // Always listen for direct Bluetooth commands
  handleBluetoothCommands();

  unsigned long currentMillis = millis();
  if (currentMillis - lastPostTime >= post_interval_ms || lastPostTime == 0) {
    lastPostTime = currentMillis;

    float hum  = dht.readHumidity();
    float temp = dht.readTemperature();

    if (isnan(hum) || isnan(temp)) {
      statusLine = "DHT22 Read Err";
      updateOled(0.0, 0.0, statusLine);
      return;
    }

    Serial.printf("[Telemetry] Temp: %.1f C | Hum: %.1f %%\n", temp, hum);

    // MODE 1: Bluetooth Broadcast (If phone is in close proximity)
    if (SerialBT.hasClient()) {
      SerialBT.printf("{\"device\":\"%s\",\"temp\":%.1f,\"hum\":%.1f}\n", device_id.c_str(), temp, hum);
      statusLine = "BT Direct Link Active";
    }

    // MODE 2: Long-Range Wi-Fi Sync (Upload to Central Server)
    if (WiFi.status() == WL_CONNECTED) {
      uploadToServer(temp, hum);
    } else if (!SerialBT.hasClient()) {
      statusLine = "Offline Standby";
    }

    // Refresh Local OLED
    updateOled(temp, hum, statusLine);
  }

  delay(30);
}
