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
    final alerts = env.alerts;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Alerts & Thresholds',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Server Connection Settings',
            onPressed: () => _showServerSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Configure Thresholds',
            onPressed: () => _showThresholdSettingsDialog(context),
          ),
        ],
      ),
      body: alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 48),
                  SizedBox(height: 12),
                  Text(
                    'All environmental readings are normal',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No thresholds violated.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alert.isAcknowledged
                          ? const Color(0xFF334155)
                          : const Color(0xFFEF4444).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        alert.isAcknowledged ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: alert.isAcknowledged ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AlertBadge(
                                  alertType: alert.alertType,
                                  isAcknowledged: alert.isAcknowledged,
                                ),
                                Text(
                                  DateFormat('HH:mm:ss').format(alert.timestamp),
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Source: ${alert.source} | Value: ${alert.triggeredValue} (Limit: ${alert.thresholdValue})',
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (!alert.isAcknowledged)
                        IconButton(
                          icon: const Icon(Icons.done, color: Color(0xFF38BDF8)),
                          tooltip: 'Acknowledge',
                          onPressed: () => env.acknowledgeAlert(alert.id),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showServerSettingsDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Backend Server URL', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend IP/URL (e.g., http://192.168.1.50:8080 or http://10.0.2.2:8080 for emulator):',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Server URL',
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              ApiService.setBaseUrl(controller.text);
              Provider.of<EnvironmentProvider>(context, listen: false).fetchData();
              Navigator.pop(ctx);
            },
            child: const Text('Save & Reconnect', style: TextStyle(color: Color(0xFF0F172A))),
          ),
        ],
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
          title: Row(
            children: const [
              Icon(Icons.lock_outline, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Admin Access Required', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'Threshold configuration is restricted to Administrators.\n\nCurrent Mode: ${env.username} (${env.userRole.toUpperCase()})\n\nPlease log in as Admin using the Profile icon (👤) in the top bar.',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Color(0xFF38BDF8))),
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
        title: const Text('Configure Temperature Thresholds (Admin)', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minTController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Min Temperature (°C)',
                labelStyle: TextStyle(color: Color(0xFF38BDF8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxTController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () async {
              final minV = double.tryParse(minTController.text) ?? 18.0;
              final maxV = double.tryParse(maxTController.text) ?? 32.0;
              await ApiService.updateThreshold('temperature', minV, maxV);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temperature threshold updated!')),
                );
              }
            },
            child: const Text('Save Limits', style: TextStyle(color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
