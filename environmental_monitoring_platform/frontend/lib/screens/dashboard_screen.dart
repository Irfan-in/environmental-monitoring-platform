import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();

    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;
    final comparison = env.comparisonData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Environmental Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: env.isAdmin
                  ? const Color(0xFF10B981)
                  : (env.isLoggedIn ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
              child: Icon(
                env.isAdmin
                    ? Icons.admin_panel_settings
                    : (env.isLoggedIn ? Icons.person : Icons.person_outline),
                size: 16,
                color: env.isLoggedIn ? Colors.black : Colors.white,
              ),
            ),
            tooltip: env.isLoggedIn
                ? '${env.username} (${env.userRole.toUpperCase()})'
                : 'Account & Cloud Backup',
            onPressed: () => _showProfileSheet(context, env),
          ),
          IconButton(
            icon: env.isSyncingWeather
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_sync_outlined),
            tooltip: 'Sync Outdoor Weather',
            onPressed: () => env.syncWeather(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => env.fetchData(),
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
                  const Text(
                    'INDOOR ENVIRONMENT',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                        const SizedBox(width: 4),
                        Text(
                          indoor != null ? indoor.deviceId : 'ESP32 Offline',
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
                      value: indoor != null ? indoor.temperature.toStringAsFixed(1) : '--',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: const Color(0xFFF87171),
                      subtitle: indoor != null
                          ? 'Updated ${DateFormat('HH:mm:ss').format(indoor.timestamp)}'
                          : 'Awaiting sensor...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Humidity',
                      value: indoor != null ? indoor.humidity.toStringAsFixed(1) : '--',
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
                            'Cached (${outdoor.cachedAt != null ? DateFormat('HH:mm').format(outdoor.cachedAt!) : '24h'})',
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
                      outdoor != null ? outdoor.city : 'Weather API',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Outdoor Metric Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Outdoor Temp',
                      value: outdoor != null ? outdoor.temperature.toStringAsFixed(1) : '--',
                      unit: '°C',
                      icon: Icons.wb_sunny_outlined,
                      accentColor: const Color(0xFFFB923C),
                      subtitle: outdoor != null ? outdoor.weatherDesc : 'Open-Meteo',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Outdoor Humidity',
                      value: outdoor != null ? outdoor.humidity.toStringAsFixed(1) : '--',
                      unit: '%',
                      icon: Icons.cloud_outlined,
                      accentColor: const Color(0xFF38BDF8),
                      subtitle: outdoor != null ? 'Wind: ${outdoor.windSpeed} km/h' : '--',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thermal Comfort Overview Card
              if (comparison != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF162033)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.shield_moon_outlined, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Thermal Comfort Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        comparison.comfortAssessment,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comparison.statusSummary,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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

  void _showProfileSheet(BuildContext context, EnvironmentProvider env) {
    final userController = TextEditingController();
    final passController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
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
                          color: const Color(0xFF475569),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: env.isAdmin
                              ? const Color(0xFF10B981)
                              : (env.isLoggedIn ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
                          child: Icon(
                            env.isAdmin
                                ? Icons.admin_panel_settings
                                : (env.isLoggedIn ? Icons.person : Icons.person_outline),
                            color: env.isLoggedIn ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              env.isLoggedIn ? env.username : 'Guest (Offline Mode)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              env.isLoggedIn
                                  ? 'Role: ${env.userRole.toUpperCase()}'
                                  : 'No login required for local monitoring',
                              style: TextStyle(
                                color: env.isAdmin
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: env.isAdmin ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (env.isLoggedIn)
                          TextButton.icon(
                            icon: const Icon(Icons.logout, size: 16, color: Color(0xFFEF4444)),
                            label: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                            onPressed: () {
                              env.logout();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logged out. Returned to Guest mode.')),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF334155)),
                    const SizedBox(height: 12),

                    // If Not Logged In: Show Quick Login Form
                    if (!env.isLoggedIn) ...[
                      const Text(
                        'Cloud Sync & Admin Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Log in to unlock remote cloud restore and admin threshold management.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: userController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFF64748B), size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF64748B), size: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF334155)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Auto fill admin demo button
                          ActionChip(
                            avatar: const Icon(Icons.key, size: 14, color: Color(0xFF38BDF8)),
                            label: const Text('Fill Admin (Demo)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                            backgroundColor: const Color(0xFF38BDF8).withOpacity(0.12),
                            side: BorderSide.none,
                            onPressed: () {
                              setSheetState(() {
                                userController.text = 'admin';
                                passController.text = 'admin123';
                              });
                            },
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final u = userController.text.trim();
                              final p = passController.text.trim();
                              if (u.isEmpty || p.isEmpty) return;
                              final err = await env.login(u, p);
                              if (!ctx.mounted) return;
                              if (err == null) {
                                Navigator.pop(ctx);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Logged in as ${env.username} (${env.userRole.toUpperCase()})'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err), backgroundColor: const Color(0xFFEF4444)),
                                );
                              }
                            },
                            child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFF334155)),
                      const SizedBox(height: 12),
                    ],

                    // Cloud Backup & Restore Actions
                    const Text(
                      'CLOUD BACKUP & DISASTER RECOVERY',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Backup or restore complete sensor telemetry history, alert records, and threshold configurations.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 14),
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
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF475569)),
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
