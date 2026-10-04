# Cross-Platform Flutter Environmental Dashboard

This is the presentation dashboard for the **Integrated Environmental Monitoring Platform** built using Flutter (Dart).

---

## 1. Features
- **Dashboard Screen**: Real-time indoor temperature & humidity telemetry from ESP32 alongside outdoor Open-Meteo weather parameters.
- **Comparison Screen**: Side-by-side environmental analysis, temperature ($\Delta T$) & humidity ($\Delta H$) differentials, and ASHRAE 55 thermal comfort assessments.
- **Historical Charts**: Dual-line graph trends powered by `fl_chart` for monitoring sensor patterns over time.
- **Alerts & Thresholds**: Real-time alert notifications with acknowledgment capabilities and interactive safe boundary configuration.
- **Responsive Layout**: Adapts between phone layout (Bottom Navigation Bar) and tablet/desktop/web (Navigation Rail).

---

## 2. Requirements
- Flutter SDK `>= 3.10.0`
- Android Studio or Visual Studio Code with Flutter & Dart extensions installed

---

## 3. Getting Started

### Step 1: Install Dependencies
Open a terminal in this `frontend/` directory and run:
```bash
flutter pub get
```

### Step 2: Configure Backend Connection
By default, the app attempts to connect to `http://localhost:8080`.
- **For Android Emulator**: Connects to `http://10.0.2.2:8080` (Android's loopback alias to host machine).
- **For Physical Android/iOS Device**: Connect your phone and PC to the same Wi-Fi network or mobile hotspot. Open `frontend/lib/services/api_service.dart` or tap the **Network Icon** in the app's **Alerts tab** and enter your computer's local Wi-Fi IP address (e.g., `http://192.168.1.100:8080`).

### Step 3: Run the Application
- **Run on Chrome (Web Preview)**:
  ```bash
  flutter run -d chrome
  ```
- **Run on Android Emulator or Connected Device**:
  ```bash
  flutter run
  ```
- **Build Release APK**:
  ```bash
  flutter build apk --release
  ```
