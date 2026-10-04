/*
 * ==============================================================================
 * Integrated Environmental Monitoring Platform - Hardware Sensing Node
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
 * Network Strategy:
 *   - Connects to Mobile Phone Hotspot (2.4 GHz).
 *   - Automatically targets the phone's Gateway IP on port 8080 via WiFi.gatewayIP().
 *   - Eliminates hardcoded IP mismatches across different phone brands.
 * ==============================================================================
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <ArduinoJson.h>

// ==============================================================================
// 1. Wi-Fi Configuration
// ==============================================================================
// Change these to match your Phone's Hotspot exactly:
const char* WIFI_SSID     = "Irfan";          // Your phone hotspot name
const char* WIFI_PASSWORD = "password123";    // Your phone hotspot password

const char* DEVICE_ID     = "esp32_node_01";
const unsigned long POST_INTERVAL_MS = 3000; // Send reading every 3 seconds

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
String postStatus = "Init...";

// ==============================================================================
// OLED Display Helper
// ==============================================================================
void updateOled(float temp, float hum, String status) {
  display.clearDisplay();
  
  // Header
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.print("ENV MONITOR [ESP32]");
  display.drawLine(0, 9, 127, 9, SSD1306_WHITE);

  // Temperature (Big Font)
  display.setCursor(0, 14);
  display.print("Temp: ");
  display.setTextSize(2);
  display.print(temp, 1);
  display.setTextSize(1);
  display.print(" C");

  // Humidity (Big Font)
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
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 5);
  display.println("Connecting Hotspot:");
  display.println(WIFI_SSID);
  display.display();

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 25) {
    delay(500);
    Serial.print(".");
    display.print(".");
    display.display();
    attempts++;
  }

  display.clearDisplay();
  display.setCursor(0, 5);
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected successfully!");
    Serial.print("[WiFi] ESP32 IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("[WiFi] Gateway (Phone) IP: ");
    Serial.println(WiFi.gatewayIP());

    display.println("WiFi Connected!");
    display.println();
    display.print("ESP:  ");
    display.println(WiFi.localIP().toString());
    display.print("Host: ");
    display.println(WiFi.gatewayIP().toString());
  } else {
    Serial.println("\n[WiFi] Connection failed. Retrying...");
    display.println("WiFi Failed!");
    display.println("Check 2.4GHz Hotspot");
  }
  display.display();
  delay(2000);
}

// ==============================================================================
// HTTP Data Transmission Routine
// ==============================================================================
void sendData(float temp, float hum) {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
    if (WiFi.status() != WL_CONNECTED) {
      postStatus = "WiFi Disconnected";
      return;
    }
  }

  // Automatically construct server URL using the phone's Gateway IP!
  String serverUrl = "http://" + WiFi.gatewayIP().toString() + ":8080/api/indoor/reading";

  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(4000); // 4 second timeout

  // Build JSON document compatible with both ArduinoJson v6 and v7
  #if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
  #else
    StaticJsonDocument<256> doc;
  #endif

  doc["device_id"]   = DEVICE_ID;
  doc["temperature"] = serialized(String(temp, 1));
  doc["humidity"]    = serialized(String(hum, 1));

  String payload;
  serializeJson(doc, payload);

  Serial.println("[HTTP] Target: " + serverUrl);
  Serial.println("[HTTP] Sending: " + payload);

  int httpCode = http.POST(payload);
  if (httpCode > 0) {
    Serial.printf("[HTTP] Response Code: %d\n", httpCode);
    if (httpCode == 200 || httpCode == 201) {
      postStatus = "POST OK [200]";
    } else {
      postStatus = "HTTP " + String(httpCode);
    }
  } else {
    Serial.printf("[HTTP] POST Error: %s\n", http.errorToString(httpCode).c_str());
    postStatus = "Net Err " + String(httpCode) + " (Check Server)";
  }
  http.end();
}

// ==============================================================================
// Setup
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(500);

  // Initialize I2C OLED (SDA=21, SCL=22)
  Wire.begin(21, 22);
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDR)) {
    Serial.println("[OLED] SSD1306 initialization failed. Check wiring!");
  } else {
    display.clearDisplay();
    display.display();
  }

  // Initialize DHT22
  dht.begin();
  Serial.println("[DHT22] Initialized on GPIO 4");

  // Connect to Hotspot
  connectToWiFi();
}

// ==============================================================================
// Main Loop
// ==============================================================================
void loop() {
  unsigned long currentMillis = millis();

  if (currentMillis - lastPostTime >= POST_INTERVAL_MS || lastPostTime == 0) {
    lastPostTime = currentMillis;

    float hum  = dht.readHumidity();
    float temp = dht.readTemperature(); // Celsius

    if (isnan(hum) || isnan(temp)) {
      Serial.println("[Sensor] Error reading from DHT22!");
      postStatus = "DHT22 Error";
      updateOled(0.0, 0.0, postStatus);
      return;
    }

    Serial.printf("[Sensor] Temp: %.1f C | Hum: %.1f %%\n", temp, hum);

    // Send data to backend running on the phone
    sendData(temp, hum);

    // Refresh OLED
    updateOled(temp, hum, postStatus);
  }

  delay(50);
}
