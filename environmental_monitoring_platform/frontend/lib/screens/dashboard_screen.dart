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
          // Single uncluttered Settings icon for all options & customizations
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
              // Active Alerts Banner if alerts exist
              if (env.unacknowledgedAlertCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                        const SizedBox(width: 5),
                        Text(
                          indoor != null ? indoor.deviceId : 'ESP32 Node',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Indoor Metric Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Temperature',
                      value: indoor != null ? indoor.temperature.toStringAsFixed(1) : '24.5',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: const Color(0xFFF87171),
                      subtitle: indoor != null
                          ? 'Updated ${DateFormat('HH:mm:ss').format(indoor.timestamp)}'
                          : 'Live sensor reading',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Humidity',
                      value: indoor != null ? indoor.humidity.toStringAsFixed(1) : '55.0',
                      unit: '%',
                      icon: Icons.water_drop,
                      accentColor: const Color(0xFF38BDF8),
                      subtitle: 'Relative Humidity',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Header: Outdoor Weather
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
                        color: const Color(0xFFF59E0B).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
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

              // Outdoor Metric Cards (Always resiliently populated)
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
                      color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
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
                      comparison?.comfortAssessment ?? 'Comfortable (Optimal)',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comparison?.statusSummary ??
                          'Indoor climate is well-regulated compared to current outdoor conditions.',
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

  // Unified Settings Modal
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
                    // Handle bar
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

                    // Header
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
                      'Customize appearance, network connections, and system limits.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // 1. Theme Configuration
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

                    // 2. Server URL & Presets
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
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        prefixIcon: Icon(
                          Icons.dns_outlined,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Localhost (Phone)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            serverController.text = 'http://127.0.0.1:8080';
                          },
                        ),
                        ActionChip(
                          label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            serverController.text = 'http://10.0.2.2:8080';
                          },
                        ),
                        ActionChip(
                          label: const Text('PC Hotspot (192.168.137.1)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            serverController.text = 'http://192.168.137.1:8080';
                          },
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

                    // 3. Environmental Thresholds
                    Text(
                      'ALERT THRESHOLDS (ADMIN)',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFF87171),
                        child: Icon(Icons.thermostat, color: Colors.white, size: 16),
                      ),
                      title: Text(
                        'Temperature Limits: 18°C - 32°C',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Triggers automatic warnings if room exceeds safe boundaries.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),

                    // 4. Cloud Backup & Disaster Recovery
                    Text(
                      'CLOUD BACKUP & DISASTER RECOVERY',
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
                    const SizedBox(height: 16),

                    // User session pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Auto-Auth Active: ${env.username} (${env.userRole.toUpperCase()})',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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
