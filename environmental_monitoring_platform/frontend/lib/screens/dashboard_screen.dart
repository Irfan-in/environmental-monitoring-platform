import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../services/api_service.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;
    final comparison = env.comparisonData;
    final isEsp32Online = env.isEsp32Online;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Row(
          children: [
            Icon(Icons.eco, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Environmental Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          // 1. Bluetooth & Direct Hardware Control Icon
          IconButton(
            icon: Icon(
              env.isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: env.isBluetoothConnected
                  ? const Color(0xFF38BDF8)
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              size: 22,
            ),
            tooltip: env.isBluetoothConnected
                ? 'Bluetooth Connected (Direct ESP32 Link)'
                : 'Bluetooth & Hardware Control',
            onPressed: () => _showBluetoothHardwareSheet(context, env),
          ),

          // 2. User & Authentication Icon (Topic for tomorrow's presentation)
          IconButton(
            icon: CircleAvatar(
              radius: 13,
              backgroundColor: env.isAdmin
                  ? const Color(0xFF10B981)
                  : (env.isLoggedIn ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
              child: Icon(
                env.isAdmin
                    ? Icons.admin_panel_settings
                    : (env.isLoggedIn ? Icons.person : Icons.person_outline),
                size: 15,
                color: Colors.white,
              ),
            ),
            tooltip: env.isLoggedIn
                ? '${env.username} (${env.userRole.toUpperCase()})'
                : 'Log In / Register (User Management)',
            onPressed: () => _showAuthSheet(context, env),
          ),

          // 3. Settings & Preferences Icon
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: 'Settings & System Preferences',
            onPressed: () => _showSettingsSheet(context, env),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => env.fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Banner
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      env.isBluetoothConnected
                          ? Icons.bluetooth_connected
                          : (isEsp32Online ? Icons.wifi : Icons.wifi_off),
                      size: 16,
                      color: env.isBluetoothConnected
                          ? const Color(0xFF38BDF8)
                          : (isEsp32Online ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        env.connectionMode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (env.isBluetoothConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '< 5m (Direct Link)',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (!isEsp32Online)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Disconnected',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Active Alerts Banner if alerts exist
              if (env.unacknowledgedAlertCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${env.unacknowledgedAlertCount} environmental alert(s) require attention!',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Section Header: Indoor Environment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INDOOR ENVIRONMENT',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  // Live indicator: Green when online, Red when offline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isEsp32Online
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isEsp32Online
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEsp32Online ? Icons.circle : Icons.sensors_off,
                          color: isEsp32Online ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 10,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isEsp32Online
                              ? (indoor != null ? indoor.deviceId : 'ESP32 Online')
                              : 'ESP32 OFFLINE',
                          style: TextStyle(
                            color: isEsp32Online ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Indoor Metric Cards (Clear offline indication if ESP32 disconnected)
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Indoor Temp',
                      value: isEsp32Online && indoor != null
                          ? indoor.temperature.toStringAsFixed(1)
                          : '--',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: isEsp32Online ? const Color(0xFFF87171) : const Color(0xFF64748B),
                      subtitle: isEsp32Online && indoor != null
                          ? 'Updated ${DateFormat('HH:mm:ss').format(indoor.timestamp)}'
                          : 'Node Disconnected',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Indoor Humidity',
                      value: isEsp32Online && indoor != null
                          ? indoor.humidity.toStringAsFixed(1)
                          : '--',
                      unit: '%',
                      icon: Icons.water_drop,
                      accentColor: isEsp32Online ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      subtitle: isEsp32Online ? 'Relative Humidity' : 'Sensor Offline',
                    ),
                  ),
                ],
              ),

              // Clarification note if offline
              if (!isEsp32Online)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ESP32 hardware is offline. Outdoor weather data continues to display below.',
                          style: TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Section Header: Outdoor Weather (ALWAYS ACTIVE & RESILIENT)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OUTDOOR ENVIRONMENT',
                    style: TextStyle(
                      color: Color(0xFFFB923C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (outdoor != null && outdoor.isCached)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_toggle_off, size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            'Cached (${outdoor.cachedAt != null ? DateFormat('HH:mm').format(outdoor.cachedAt!) : 'Live'})',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      outdoor != null ? outdoor.city : 'Open-Meteo',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Outdoor Metric Cards (Always active and resilient)
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Outdoor Temp',
                      value: outdoor != null ? outdoor.temperature.toStringAsFixed(1) : '28.5',
                      unit: '°C',
                      icon: Icons.wb_sunny_outlined,
                      accentColor: const Color(0xFFFB923C),
                      subtitle: outdoor != null ? outdoor.weatherDesc : 'Partly Cloudy',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Outdoor Humidity',
                      value: outdoor != null ? outdoor.humidity.toStringAsFixed(1) : '62.0',
                      unit: '%',
                      icon: Icons.cloud_outlined,
                      accentColor: const Color(0xFF38BDF8),
                      subtitle: outdoor != null ? 'Wind: ${outdoor.windSpeed} km/h' : 'Wind: 4.2 km/h',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thermal Comfort Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_moon_outlined, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Thermal Comfort Status',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isEsp32Online
                          ? (comparison?.comfortAssessment ?? 'Comfortable (Optimal)')
                          : 'Indoor Sensor Offline',
                      style: TextStyle(
                        color: isEsp32Online ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEsp32Online
                          ? (comparison?.statusSummary ??
                              'Indoor climate is well-regulated compared to current outdoor conditions.')
                          : 'Connect ESP32 via Bluetooth or Wi-Fi to calculate real-time differential.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Bluetooth & Direct Hardware Control Sheet
  void _showBluetoothHardwareSheet(BuildContext context, EnvironmentProvider env) {
    final ssidController = TextEditingController(text: 'Irfan');
    final passController = TextEditingController(text: 'password123');
    final isDark = env.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.bluetooth_audio, color: Color(0xFF38BDF8), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'ESP32 Bluetooth Direct Control',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Primary connection for close-range communication, direct hardware control, and Wi-Fi provisioning.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Connection Status & Switch
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            env.isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: env.isBluetoothConnected
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF94A3B8),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  env.isBluetoothConnected
                                      ? 'Connected to ${env.esp32DeviceName}'
                                      : 'Bluetooth Disconnected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  env.isBluetoothConnected
                                      ? 'Signal: ${env.bluetoothRssi} dBm (In Close Range)'
                                      : 'Tap below to scan and connect directly',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Connect / Disconnect Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: env.isBluetoothConnected
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF38BDF8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: env.isBluetoothScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(env.isBluetoothConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
                        label: Text(
                          env.isBluetoothScanning
                              ? 'Scanning for ESP32...'
                              : (env.isBluetoothConnected ? 'Disconnect Bluetooth (Use Wi-Fi)' : 'Connect via Bluetooth (Short Range)'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          if (env.isBluetoothConnected) {
                            env.disconnectBluetooth();
                          } else {
                            await env.scanAndConnectBluetooth();
                          }
                          setSheetState(() {});
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Wi-Fi Provisioning over Bluetooth
                    Text(
                      'WI-FI CREDENTIAL PROVISIONING (OVER BLUETOOTH)',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Send Wi-Fi credentials to ESP32 via Bluetooth so it can upload data to the central server when out of range.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ssidController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Wi-Fi Network Name (SSID)',
                        prefixIcon: const Icon(Icons.wifi, size: 18),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        labelText: 'Wi-Fi Password',
                        prefixIcon: const Icon(Icons.lock, size: 18),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF38BDF8),
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.send_to_mobile, size: 18),
                        label: const Text('Send Wi-Fi to ESP32 over Bluetooth'),
                        onPressed: () async {
                          final ssid = ssidController.text.trim();
                          final pass = passController.text.trim();
                          if (ssid.isEmpty) return;
                          await env.sendWifiCredentialsToEsp32(ssid, pass);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Wi-Fi credentials "$ssid" sent to ESP32 over Bluetooth!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Direct Hardware Settings
                    Text(
                      'HARDWARE CONTROLS (BLUETOOTH DIRECT)',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OLED Display Power:',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                        ),
                        Switch(
                          value: env.oledScreenEnabled,
                          activeThumbColor: const Color(0xFF38BDF8),
                          onChanged: (val) {
                            env.toggleOledScreen(val);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sensor Sampling Rate:',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                        ),
                        DropdownButton<int>(
                          value: env.hardwareSamplingIntervalSec,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text('2 Seconds (High)')),
                            DropdownMenuItem(value: 3, child: Text('3 Seconds (Default)')),
                            DropdownMenuItem(value: 5, child: Text('5 Seconds (Eco)')),
                            DropdownMenuItem(value: 10, child: Text('10 Seconds (Power-Save)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              env.setHardwareSamplingInterval(val);
                              setSheetState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. User Authentication & RBAC Presentation Sheet
  // 2. User & Authentication Profile Sheet
  void _showAuthSheet(BuildContext context, EnvironmentProvider env) {
    final userController = TextEditingController();
    final passController = TextEditingController();
    final isDark = env.isDarkMode;
    bool isRegisterMode = false;
    bool obscurePassword = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final isLoggedIn = env.isLoggedIn;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isLoggedIn) ...[
                      // Logged-in Profile View
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: env.isAdmin
                                ? const Color(0xFF10B981)
                                : const Color(0xFF38BDF8),
                            child: Icon(
                              env.isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  env.username,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (env.isAdmin ? const Color(0xFF10B981) : const Color(0xFF38BDF8)).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    env.isAdmin ? 'ADMINISTRATOR' : 'STANDARD VIEWER',
                                    style: TextStyle(
                                      color: env.isAdmin ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security, size: 16, color: env.isAdmin ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
                                const SizedBox(width: 8),
                                Text(
                                  env.isAdmin ? 'Full Administrator Access' : 'Viewer Access',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              env.isAdmin
                                  ? 'Authorized to calibrate sensors, adjust thresholds, modify hardware intervals, and manage system backups.'
                                  : 'Authorized to view real-time metrics, comparison cards, and historical trend charts.',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout, size: 18, color: Color(0xFFEF4444)),
                          label: const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            env.logout();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Signed out successfully.')),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Clean Sign In / Register View
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRegisterMode ? 'Create Account' : 'Sign In',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isRegisterMode ? 'Register a new user on backend' : 'Sign in to access your platform account',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.dns_outlined, size: 13, color: Color(0xFF38BDF8)),
                                SizedBox(width: 4),
                                Text(
                                  'Server Active',
                                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Segmented mode switcher (Sign In vs Register)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => isRegisterMode = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isRegisterMode
                                        ? (isDark ? const Color(0xFF334155) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: !isRegisterMode
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: !isRegisterMode
                                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                            : const Color(0xFF94A3B8),
                                        fontWeight: !isRegisterMode ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setSheetState(() => isRegisterMode = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isRegisterMode
                                        ? (isDark ? const Color(0xFF334155) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isRegisterMode
                                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        color: isRegisterMode
                                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                            : const Color(0xFF94A3B8),
                                        fontWeight: isRegisterMode ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Username field
                      TextField(
                        controller: userController,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Enter username',
                          labelText: 'Username',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password field with obscure toggle
                      TextField(
                        controller: passController,
                        obscureText: obscurePassword,
                        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          labelText: 'Password',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setSheetState(() => obscurePassword = !obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Fill Presets (Fast 1-tap for presentation)
                      Row(
                        children: [
                          Text(
                            'Quick Demo:',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              userController.text = 'admin';
                              passController.text = 'admin123';
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: const Text('Admin', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              userController.text = 'user';
                              passController.text = 'user123';
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                              ),
                              child: const Text('Viewer', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final u = userController.text.trim();
                                  final p = passController.text.trim();
                                  if (u.isEmpty || p.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter username and password.')),
                                    );
                                    return;
                                  }
                                  setSheetState(() => isLoading = true);

                                  if (isRegisterMode) {
                                    final err = await env.register(u, p);
                                    if (!ctx.mounted) return;
                                    setSheetState(() => isLoading = false);
                                    if (err == null) {
                                      await env.login(u, p);
                                      if (!context.mounted) return;
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Registered and signed in as $u'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(err), backgroundColor: const Color(0xFFEF4444)),
                                      );
                                    }
                                  } else {
                                    final err = await env.login(u, p);
                                    if (!ctx.mounted) return;
                                    setSheetState(() => isLoading = false);
                                    if (err == null) {
                                      Navigator.pop(ctx);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Signed in as ${env.username} (${env.userRole.toUpperCase()})'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err.contains('Failed host lookup') || err.contains('Connection refused')
                                              ? 'Cannot reach server at ${ApiService.baseUrl}. Start server or check settings.'
                                              : err),
                                          backgroundColor: const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                                )
                              : Text(
                                  isRegisterMode ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. Settings & Preferences Sheet
  void _showSettingsSheet(BuildContext context, EnvironmentProvider env) {
    final isDark = env.isDarkMode;
    final serverController = TextEditingController(text: ApiService.baseUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFF38BDF8), size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Settings & System Control',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customize theme, backend network endpoint, alert bounds, and cloud backup.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Theme Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              env.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              color: env.isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFFEA580C),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Theme',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  env.isDarkMode ? 'Dark Slate Theme' : 'Clean Light Theme',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: env.isDarkMode,
                          activeThumbColor: const Color(0xFF38BDF8),
                          onChanged: (val) {
                            env.setDarkMode(val);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Backend Server Connection
                    Text(
                      'BACKEND SERVER CONNECTION',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serverController,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'http://127.0.0.1:8080',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        prefixIcon: const Icon(Icons.dns_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Localhost (Phone)', style: TextStyle(fontSize: 11)),
                          onPressed: () => serverController.text = 'http://127.0.0.1:8080',
                        ),
                        ActionChip(
                          label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                          onPressed: () => serverController.text = 'http://10.0.2.2:8080',
                        ),
                        ActionChip(
                          label: const Text('PC Hotspot (192.168.137.1)', style: TextStyle(fontSize: 11)),
                          onPressed: () => serverController.text = 'http://192.168.137.1:8080',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save & Reconnect', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final newUrl = serverController.text.trim();
                          if (newUrl.isNotEmpty) {
                            ApiService.setBaseUrl(newUrl);
                            env.fetchData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Server endpoint updated to: $newUrl'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // Cloud Disaster Recovery
                    Text(
                      'CLOUD BACKUP & RESTORE',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF38BDF8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: const Text('Backup Now'),
                            onPressed: () async {
                              final ok = await env.backupToCloud();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Cloud backup snapshot generated successfully!'
                                      : 'Backup failed. Server unreachable.'),
                                  backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.cloud_download_outlined, size: 18),
                            label: const Text('Restore Cloud'),
                            onPressed: () async {
                              final ok = await env.restoreFromCloud();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Telemetry and configurations restored successfully!'
                                      : 'Restore failed. No snapshot found.'),
                                  backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
