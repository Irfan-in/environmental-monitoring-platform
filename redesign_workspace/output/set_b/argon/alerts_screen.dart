import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../services/api_service.dart';
import '../widgets/alert_badge.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alerts = env.alerts;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF15192B),
              Color(0xFF201D3A),
              Color(0xFF292240),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7E2F8),
              Color(0xFFEDE7FA),
              Color(0xFFF3DEC4),
            ],
          );

    final cardBg = isDark
        ? const Color(0xFF272544).withValues(alpha: 0.9)
        : const Color(0xFFE5DEFA).withValues(alpha: 0.78);
    final primaryText = isDark ? Colors.white : const Color(0xFF1B1C22);
    final secondaryText =
        isDark ? const Color(0xFFB3B6CE) : const Color(0xFF5A5D72);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Top Header Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alerts & Thresholds',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: primaryText,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.done_all_rounded,
                              color: Color(0xFF10B981)),
                          tooltip: 'Acknowledge All Alerts',
                          onPressed: () async {
                            await env.acknowledgeAllAlerts();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('All alerts acknowledged!')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.tune_rounded, color: primaryText),
                          tooltip: 'Configure Thresholds',
                          onPressed: () =>
                              _showThresholdSettingsDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Hero Summary Banner (Lavender Redesign Top Summary Style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alerts.isEmpty
                                  ? 'All Nominal'
                                  : '${alerts.length} Logged Events',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              env.activeClimateAdvisory ??
                                  'Microclimate parameters within ASHRAE 55 limits',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: alerts.isEmpty
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          alerts.isEmpty
                              ? Icons.wb_sunny_rounded
                              : Icons.warning_amber_rounded,
                          color: alerts.isEmpty
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. Alerts List ("10 days" Lavender Cards Style)
              Expanded(
                child: alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: Color(0xFF10B981), size: 54),
                            const SizedBox(height: 12),
                            Text(
                              'All environmental readings are normal',
                              style: TextStyle(
                                color: primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No thresholds violated.',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          AlertBadge(
                                            alertType: alert.alertType,
                                            isAcknowledged:
                                                alert.isAcknowledged,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('HH:mm:ss')
                                                .format(alert.timestamp),
                                            style: TextStyle(
                                              color: secondaryText,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        alert.message,
                                        style: TextStyle(
                                          color: primaryText,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Source: ${alert.source}',
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: primaryText.withValues(alpha: 0.15),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${alert.triggeredValue}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: primaryText,
                                      ),
                                    ),
                                    Text(
                                      'Limit ${alert.thresholdValue}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                if (!alert.isAcknowledged)
                                  IconButton(
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF335594)),
                                    tooltip: 'Acknowledge',
                                    onPressed: () =>
                                        env.acknowledgeAlert(alert.id),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThresholdSettingsDialog(BuildContext context) {
    final env = Provider.of<EnvironmentProvider>(context, listen: false);
    if (!env.isAdmin) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Admin Access Required',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'Threshold configuration is restricted to Administrators.\n\nCurrent Mode: ${env.username} (${env.userRole.toUpperCase()})',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFF38BDF8))),
            ),
          ],
        ),
      );
      return;
    }

    final minTController = TextEditingController(text: '18.0');
    final maxTController = TextEditingController(text: '32.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Configure Temperature Thresholds',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minTController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Min Temperature (°C)',
                labelStyle: TextStyle(color: Color(0xFF38BDF8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxTController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Max Temperature (°C)',
                labelStyle: TextStyle(color: Color(0xFF38BDF8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () async {
              final minV = double.tryParse(minTController.text) ?? 18.0;
              final maxV = double.tryParse(maxTController.text) ?? 32.0;
              await ApiService.updateThreshold('temperature', minV, maxV);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Temperature threshold updated!')),
                );
              }
            },
            child: const Text('Save Limits',
                style: TextStyle(color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
