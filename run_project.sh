#!/bin/bash

# ==========================================================
# Environmental Monitoring Platform - Project Launcher
# ==========================================================

set -e

PROJECT_DIR="/home/user/Shahabas/environmental_monitoring_platform"

BACKEND_DIR="$PROJECT_DIR/backend"
ESP32_DIR="$PROJECT_DIR/esp32"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Android SDK
ANDROID_HOME="/home/user/Android/Sdk"
ANDROID_SDK_ROOT="$ANDROID_HOME"

# Your Android Studio AVD
AVD_NAME="Pixel_9"

# Flutter emulator/device
DEVICE_ID="emulator-5554"

echo "=========================================="
echo " Environmental Monitoring Platform"
echo "=========================================="

# ----------------------------------------------------------
# 1. Configure Android SDK PATH
# ----------------------------------------------------------

export ANDROID_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"

export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

echo
echo "[1/7] Checking Android SDK..."

if [ ! -d "$ANDROID_HOME" ]; then
    echo "ERROR: Android SDK not found:"
    echo "$ANDROID_HOME"
    exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
    echo "ERROR: adb is still not available."
    echo
    echo "Expected adb at:"
    echo "$ANDROID_HOME/platform-tools/adb"
    exit 1
fi

echo "Android SDK: $ANDROID_HOME"
echo "ADB: $(which adb)"

# ----------------------------------------------------------
# 2. Check emulator
# ----------------------------------------------------------

echo
echo "[2/7] Checking Android emulator..."

if ! command -v emulator >/dev/null 2>&1; then
    echo "ERROR: Android emulator command not found."
    echo "Expected:"
    echo "$ANDROID_HOME/emulator/emulator"
    exit 1
fi

# Check whether Pixel_9 is already running
if adb devices | grep -q "^$DEVICE_ID[[:space:]]*device$"; then

    echo "Pixel 9 emulator is already running."

else

    echo "Starting Android Studio AVD: $AVD_NAME"

    emulator -avd "$AVD_NAME" >/tmp/pixel9-emulator.log 2>&1 &

    EMULATOR_PID=$!

    echo "Emulator started. PID: $EMULATOR_PID"

    # ------------------------------------------------------
    # 3. Wait for emulator
    # ------------------------------------------------------

    echo
    echo "[3/7] Waiting for emulator..."

    adb wait-for-device

    echo "ADB device detected."

    echo "Waiting for Android to finish booting..."

    until adb shell getprop sys.boot_completed 2>/dev/null | grep -m 1 "1" >/dev/null
    do
        sleep 2
    done

    echo "Android boot completed."

    # Give Android a few more seconds
    sleep 3
fi

# ----------------------------------------------------------
# 4. Start Backend
# ----------------------------------------------------------

echo
echo "[4/7] Starting Central Backend Server..."

if command -v gnome-terminal >/dev/null 2>&1; then

    gnome-terminal -- bash -c "
        cd '$BACKEND_DIR'
        echo '=========================================='
        echo ' Central Backend Server'
        echo '=========================================='
        python3 run_server.py
        echo
        echo 'Backend stopped.'
        exec bash
    "

else

    echo "ERROR: gnome-terminal not found."
    echo "Please install it with:"
    echo "sudo apt install gnome-terminal"
    exit 1

fi

# Give backend time to start
sleep 3

# ----------------------------------------------------------
# 5. Start ESP32 Simulator
# ----------------------------------------------------------

echo
echo "[5/7] Starting ESP32 Live Simulator..."

SIMULATOR_MODE="${1:-normal}"

gnome-terminal -- bash -c "
    cd '$ESP32_DIR'
    echo '=========================================='
    echo ' ESP32 Live Simulator'
    echo '=========================================='
    echo 'Mode: $SIMULATOR_MODE'
    echo
    python3 simulator.py --mode '$SIMULATOR_MODE'
    echo
    echo 'Simulator stopped.'
    exec bash
"

# ----------------------------------------------------------
# 6. Open Web Dashboard
# ----------------------------------------------------------

echo
echo "[6/7] Opening Web Dashboard..."

sleep 2

if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:8080" >/dev/null 2>&1 &
fi

# ----------------------------------------------------------
# 7. Start Flutter App
# ----------------------------------------------------------

echo
echo "[7/7] Starting Flutter application..."

cd "$FRONTEND_DIR"

echo
echo "Flutter directory:"
echo "$FRONTEND_DIR"

echo
echo "Checking Flutter devices..."
flutter devices

echo
echo "Launching Flutter on Pixel 9..."
echo

flutter run -d "$DEVICE_ID"

# ----------------------------------------------------------
# End
# ----------------------------------------------------------

echo
echo "=========================================="
echo " Project stopped"
echo "=========================================="
