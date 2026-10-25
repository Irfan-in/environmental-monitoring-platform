/*
 * ==============================================================================
 * Integrated Environmental Monitoring Platform - ESP32 Sensor Node
 * ==============================================================================
 * Author : Mohammed Irfan KS
 * Roll No: KCMIT25MCA-2011
 * Program: MCA (3rd Semester)
 *
 * Hardware:
 *   - ESP32 Development Board
 *   - DHT22 Temperature & Humidity Sensor (Data: GPIO 4)
 *   - 0.96" I2C OLED SSD1306 (SDA: GPIO 21, SCL: GPIO 22)
 *
 * Function:
 *   Reads DHT22 sensor and POSTs data to the cloud backend every 5 seconds.
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

// ==============================================================================
// Configuration
// ==============================================================================
// WiFi networks to try (tries each one, first to connect wins)
const char* WIFI_NETWORKS[][2] = {
  { "Irfan",                        "11112222"   },  // Mobile hotspot (most reliable)
  { "Keralavision isp",             "11qq3210"   },  // Home router 1
  { "fayazKeralavision-Wifi-2.4G",  "9188642139" },  // Home router 2
};
const int WIFI_NETWORK_COUNT = 3;

// Cloud backend
const char* SERVER_URL = "https://environmental-monitoring-backend.onrender.com/api/indoor/reading";
const char* DEVICE_ID  = "esp32_node_01";

// Post interval (ms)
const unsigned long POST_INTERVAL = 5000;

// ==============================================================================
// Hardware pins
// ==============================================================================
#define DHTPIN        4
#define DHTTYPE       DHT22
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define SCREEN_ADDR   0x3C

DHT dht(DHTPIN, DHTTYPE);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

unsigned long lastPostTime  = 0;
unsigned long lastWifiRetry = 0;
String statusLine = "Starting...";

// ==============================================================================
// OLED helper
// ==============================================================================
void updateOled(float temp, float hum, String status) {
  display.clearDisplay();

  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  if (WiFi.status() == WL_CONNECTED) {
    display.print("WIFI: " + WiFi.SSID());
  } else {
    display.print("ENV [OFFLINE]");
  }
  display.drawLine(0, 9, 127, 9, SSD1306_WHITE);

  display.setCursor(0, 14);
  display.print("Temp: ");
  display.setTextSize(2);
  display.print(temp, 1);
  display.setTextSize(1);
  display.print(" C");

  display.setCursor(0, 34);
  display.print("Hum:  ");
  display.setTextSize(2);
  display.print(hum, 1);
  display.setTextSize(1);
  display.print(" %");

  display.drawLine(0, 52, 127, 52, SSD1306_WHITE);
  display.setCursor(0, 55);
  display.print(status);

  display.display();
}

// ==============================================================================
// Wi-Fi connection
// ==============================================================================
void connectToWiFi() {
  WiFi.mode(WIFI_STA);

  for (int i = 0; i < WIFI_NETWORK_COUNT; i++) {
    const char* ssid = WIFI_NETWORKS[i][0];
    const char* pass = WIFI_NETWORKS[i][1];

    Serial.printf("\n[WiFi] Trying: %s\n", ssid);
    WiFi.disconnect();
    delay(100);
    WiFi.begin(ssid, pass);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.printf("\n[WiFi] Connected to: %s  IP: %s\n",
                    WiFi.SSID().c_str(), WiFi.localIP().toString().c_str());
      // Use Google DNS for reliable hostname resolution
      WiFi.config(INADDR_NONE, INADDR_NONE, INADDR_NONE,
                  IPAddress(8, 8, 8, 8), IPAddress(8, 8, 4, 4));
      statusLine = "WiFi OK: " + WiFi.SSID();
      return;
    }

    Serial.printf("\n[WiFi] %s failed.\n", ssid);
  }

  Serial.println("[WiFi] All networks failed.");
  statusLine = "WiFi FAILED";
}

// ==============================================================================
// Upload to cloud
// ==============================================================================
void uploadToServer(float temp, float hum) {
  if (WiFi.status() != WL_CONNECTED) return;

  StaticJsonDocument<256> doc;
  doc["device_id"]   = DEVICE_ID;
  doc["temperature"] = round(temp * 10.0) / 10.0;
  doc["humidity"]    = round(hum  * 10.0) / 10.0;

  String payload;
  serializeJson(doc, payload);
  Serial.println("[Upload] Payload: " + payload);

  WiFiClientSecure client;
  client.setInsecure();  // Skip cert check (OK for demo)

  HTTPClient http;
  http.begin(client, SERVER_URL);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(15000);

  int code = http.POST(payload);
  Serial.printf("[Upload] HTTP code: %d\n", code);

  if (code == 200 || code == 201) {
    statusLine = "Cloud OK [" + String(code) + "]";
    Serial.println("[Upload] SUCCESS: " + http.getString());
  } else {
    statusLine = "Upload Fail:" + String(code);
    Serial.println("[Upload] Error: " + http.errorToString(code));
  }

  http.end();
}

// ==============================================================================
// Setup
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== ESP32 Environmental Monitor Starting ===");

  // OLED
  Wire.begin(21, 22);
  if (display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDR)) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 10);
    display.println("ESP32 ENV Monitor");
    display.println("Connecting WiFi...");
    display.display();
  }

  // DHT22
  dht.begin();
  Serial.println("[DHT22] Initialized on GPIO 4");

  // WiFi
  connectToWiFi();
}

// ==============================================================================
// Main loop
// ==============================================================================
void loop() {
  unsigned long now = millis();

  // Auto-reconnect WiFi if lost
  if (WiFi.status() != WL_CONNECTED &&
      (now - lastWifiRetry >= 30000 || lastWifiRetry == 0)) {
    lastWifiRetry = now;
    Serial.println("[WiFi] Reconnecting...");
    connectToWiFi();
  }

  // Periodic sensor read + upload
  if (now - lastPostTime >= POST_INTERVAL || lastPostTime == 0) {
    lastPostTime = now;

    float hum  = dht.readHumidity();
    float temp = dht.readTemperature();

    if (isnan(hum) || isnan(temp)) {
      Serial.println("[DHT22] Read error!");
      statusLine = "DHT22 Error";
      updateOled(0.0, 0.0, statusLine);
      return;
    }

    Serial.printf("[Sensor] Temp: %.1f C  Hum: %.1f %%\n", temp, hum);
    uploadToServer(temp, hum);
    updateOled(temp, hum, statusLine);
  }

  delay(50);
}
