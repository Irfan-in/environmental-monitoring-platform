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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Environmental Monitoring',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          // User Login Button (Simple User Icon)
          IconButton(
            icon: Icon(
              env.isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
              color: env.isLoggedIn ? theme.colorScheme.primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              size: 24,
            ),
            tooltip: 'User Login',
            onPressed: () => _showUserLoginSheet(context, env),
          ),

          // Settings Button (Main Configuration Hub)
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: 'Station Settings & Diagnostics',
            onPressed: () => _showSettingsSheet(context, env),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => env.fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Hardware Node Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isEsp32Online ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: isEsp32Online
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEsp32Online ? 'ESP32-ENV-01 • Active' : 'ESP32-ENV-01 • Standby',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isEsp32Online
                                ? 'Telemetry stream active via Cloud Ingestion Gateway'
                                : 'Awaiting incoming sensor signal via Gateway buffer',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEsp32Online && indoor != null)
                      Text(
                        DateFormat('HH:mm:ss').format(indoor.timestamp.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Role-Based Access Control (RBAC) Mode Chip
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: env.isLoggedIn
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: env.isLoggedIn
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      env.isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                      size: 16,
                      color: env.isLoggedIn ? const Color(0xFF10B981) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        env.isLoggedIn
                            ? 'User: ${env.username}'
                            : 'Guest Mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: env.isLoggedIn
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => _showUserLoginSheet(context, env),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          env.isLoggedIn ? 'Log Out' : 'Log In',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Single Climate Advisory Card (ONLY shown if there's an actual active condition)
              if (env.activeClimateAdvisory != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          env.activeClimateAdvisory!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => env.dismissAdvisory(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Dismiss', style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 3. Primary Microclimate Section Header
              Text(
                'INDOOR MICROCLIMATE SENSING',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              // Primary Telemetry Metric Cards (Large & Clean)
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Temperature',
                      value: isEsp32Online && indoor != null
                          ? indoor.temperature.toStringAsFixed(1)
                          : '--.-',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: const Color(0xFF38BDF8),
                      subtitle: 'DHT22 Sensor (GPIO 4)',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Relative Humidity',
                      value: isEsp32Online && indoor != null
                          ? indoor.humidity.toStringAsFixed(1)
                          : '--.-',
                      unit: '%',
                      icon: Icons.water_drop_outlined,
                      accentColor: const Color(0xFF34D399),
                      subtitle: 'Capacitive Humidity',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Outdoor Meteorological Reference Section
              Text(
                'AMBIENT METEOROLOGICAL REFERENCE',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB923C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFB923C), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outdoor != null ? outdoor.city : 'Local Area Station',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            outdoor != null ? outdoor.weatherDesc : 'Satellite Weather Sync',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          outdoor != null ? '${outdoor.temperature.toStringAsFixed(1)}°C' : '--°C',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          outdoor != null ? '${outdoor.humidity.toStringAsFixed(0)}% RH' : '--% RH',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFB923C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5. Differential & Thermal Assessment (ASHRAE 55)
              Text(
                'DIFFERENTIAL & THERMAL COMFORT (ASHRAE 55)',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.compare_arrows, color: Color(0xFF38BDF8), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Temperature Delta (ΔT)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Builder(
                          builder: (context) {
                            final diff = comparison?.tempDiff;
                            if (diff == null) {
                              return const Text('--', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
                            }
                            return Text(
                              '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: diff > 0 ? const Color(0xFFFB923C) : const Color(0xFF38BDF8),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Comfort Index',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          comparison?.comfortAssessment ?? 'Nominal Indoor Range',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 6. Local Storage Indicator Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_outlined, size: 13, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        'Device Storage: ${env.localRecordCount} telemetry records archived locally',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
      ),
    );
  }

  // --- Access Denied Dialog for Public Observer Mode ---
  void _showAccessDeniedDialog(BuildContext context, EnvironmentProvider env) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFFF59E0B), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to your account to adjust sensor calibration or change settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showUserLoginSheet(context, env);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Continue in Guest Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Clean Settings & Preferences Bottom Sheet (Operator Only) ---
  void _showSettingsSheet(BuildContext context, EnvironmentProvider env) {
    if (!env.isLoggedIn) {
      _showAccessDeniedDialog(context, env);
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final serverController = TextEditingController(text: ApiService.baseUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
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
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, color: theme.colorScheme.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. Theme Toggle
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        env.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Dark Mode Appearance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Switch(
                        value: env.isDarkMode,
                        onChanged: (val) {
                          env.toggleTheme();
                          setSheetState(() {});
                        },
                      ),
                    ),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                    // 2. Sensor Calibration Offset
                    const SizedBox(height: 8),
                    Text(
                      'HARDWARE SENSOR CALIBRATION',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Temperature Offset:',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '${env.temperatureOffset >= 0 ? '+' : ''}${env.temperatureOffset.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: env.temperatureOffset,
                      min: -5.0,
                      max: 5.0,
                      divisions: 20,
                      label: '${env.temperatureOffset >= 0 ? '+' : ''}${env.temperatureOffset.toStringAsFixed(1)}°C',
                      onChanged: (val) {
                        env.setTemperatureOffset(val);
                        setSheetState(() {});
                      },
                    ),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                    // 3. Gateway Buffer Endpoint
                    const SizedBox(height: 8),
                    Text(
                      'CLOUD GATEWAY BUFFER URL',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: serverController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'https://...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, size: 18),
                          onPressed: () {
                            ApiService.setBaseUrl(serverController.text.trim());
                            env.fetchData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gateway endpoint saved!')),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Local Data Management
                    Text(
                      'LOCAL TELEMETRY REPOSITORY',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                            label: const Text('Clear Storage', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              await env.clearLocalStorage();
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Local telemetry cache cleared.')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Force Ingest', style: TextStyle(fontSize: 12)),
                            onPressed: () async {
                              await env.fetchData();
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingested latest cloud readings!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                    // 5. User Session & Logout
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      title: Text(
                        'Log Out (${env.username})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        env.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out. Switched to Guest Mode.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Clean User Login Sheet ---
  void _showUserLoginSheet(BuildContext context, EnvironmentProvider env) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userController = TextEditingController(text: 'irfan');
    final passController = TextEditingController(text: '1234');
    String? authError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                      Icon(
                        env.isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                        color: env.isLoggedIn ? const Color(0xFF10B981) : theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        env.isLoggedIn ? 'Account: ${env.username}' : 'User Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    env.isLoggedIn
                        ? 'You are currently logged into the Environmental Monitoring Platform.'
                        : 'Enter your credentials to sign into your user profile.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (env.isLoggedIn) ...[
                    // Logged in view with clear Log Out button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Signed in as ${env.username}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await env.logout();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out. Switched to Guest Mode.')),
                            );
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    // Logged out form
                    if (authError != null) ...[
                      Text(
                        authError!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final err = await env.login(
                            userController.text.trim(),
                            passController.text.trim(),
                          );
                          if (err != null) {
                            setSheetState(() => authError = err);
                          } else {
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Welcome, ${env.username}!')),
                              );
                            }
                          }
                        },
                        child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Demo login: irfan / 1234 or admin / admin123',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
