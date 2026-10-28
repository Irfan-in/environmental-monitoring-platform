import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/models/alert_item.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/services/api_service.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final wx = Wx.of(context);

    // Sort alerts by latest timestamp first and limit to the most recent 25 events
    final sortedAlerts = List<AlertItem>.from(env.alerts)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final displayedAlerts = sortedAlerts.take(25).toList();

    return Scaffold(
      backgroundColor: wx.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Information Board',
                        style: wx.t(24, w: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Environmental advisory & threshold log',
                        style: wx.t(12, c: wx.textDim),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Threshold settings',
                  icon: Icon(Icons.tune_rounded, color: wx.text, size: 22),
                  onPressed: () => _showThresholdDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overview Readout Card
            WxCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${displayedAlerts.length}',
                          style: wx.t(52, w: FontWeight.w300, h: 1.05),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayedAlerts.isEmpty
                              ? 'All environmental metrics within limits'
                              : (displayedAlerts.length == 1
                                  ? 'Recent climate advisory logged'
                                  : 'Recent climate advisories logged'),
                          style: wx.t(13, c: wx.textDim),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: displayedAlerts.isEmpty
                          ? wx.good.withValues(alpha: 0.15)
                          : wx.warn.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      displayedAlerts.isEmpty
                          ? Icons.verified_user_outlined
                          : Icons.campaign_rounded,
                      size: 28,
                      color: displayedAlerts.isEmpty ? wx.good : wx.warn,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // List Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recorded Advisories',
                    style: wx.t(14, w: FontWeight.w600),
                  ),
                  if (displayedAlerts.isNotEmpty)
                    Text(
                      'Latest on top',
                      style: wx.t(11, c: wx.textDim),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            if (displayedAlerts.isEmpty)
              WxCard(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                child: Column(
                  children: [
                    WxIconDot(
                      icon: Icons.check_circle_outline,
                      size: 52,
                      color: wx.good,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Atmospheric Conditions Optimal',
                      style: wx.t(16, w: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Both temperature and relative humidity have stayed within safe thresholds.',
                      textAlign: TextAlign.center,
                      style: wx.t(12, c: wx.textDim, h: 1.4),
                    ),
                  ],
                ),
              )
            else
              for (final alert in displayedAlerts) ...[
                _advisoryCard(wx, alert),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _pretty(String raw) {
    final s = raw.replaceAll('_', ' ').trim();
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _num(dynamic v) => v is num ? v.toStringAsFixed(1) : '$v';

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(t.toLocal());
  }

  Widget _advisoryCard(Wx wx, AlertItem alert) {
    final isTemp = alert.parameter.toLowerCase().contains('temp');
    final icon = isTemp
        ? Icons.thermostat_rounded
        : Icons.water_drop_outlined;
    final badgeColor = isTemp ? wx.warn : wx.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: wx.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: wx.cardBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Parameter Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Message & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _pretty(alert.alertType),
                        style: wx.t(10, w: FontWeight.w600, c: badgeColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(alert.timestamp),
                      style: wx.t(11, c: wx.textDim),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.message,
                  style: wx.t(14, w: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  '${alert.source}  \u00B7  ${DateFormat('HH:mm:ss').format(alert.timestamp.toLocal())}',
                  style: wx.t(11, c: wx.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Metric Values
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_num(alert.triggeredValue)}${isTemp ? "°C" : "%"}',
                style: wx.t(16, w: FontWeight.w700, c: badgeColor),
              ),
              const SizedBox(height: 2),
              Text(
                'Limit ${_num(alert.thresholdValue)}',
                style: wx.t(10, c: wx.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── threshold dialog (admin only) ──────────────────────────────────────────

  void _showThresholdDialog(BuildContext context) {
    final env = Provider.of<EnvironmentProvider>(context, listen: false);
    final wx = Wx.of(context);

    if (!env.isAdmin) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: wx.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: Icon(Icons.lock_outline, color: wx.warn),
          title: Text('Admin access needed',
              style: wx.t(18, w: FontWeight.w500)),
          content: Text(
            'Only administrators can change threshold limits.\n\n'
            'Signed in as ${env.username} (${env.userRole.toUpperCase()}). '
            'Log in with the account icon on the dashboard.',
            style: wx.t(13, c: wx.textDim, h: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: wx.t(14, w: FontWeight.w600, c: wx.accent)),
            ),
          ],
        ),
      );
      return;
    }

    final minController = TextEditingController(text: '18.0');
    final maxController = TextEditingController(text: '32.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: wx.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Temperature limits', style: wx.t(18, w: FontWeight.w500)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: wx.field('Minimum (°C)', icon: Icons.ac_unit),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: maxController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: wx.field('Maximum (°C)', icon: Icons.local_fire_department_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: wx.t(14, c: wx.textDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: wx.accent,
              foregroundColor: wx.onAccent,
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              final minV = double.tryParse(minController.text) ?? 18.0;
              final maxV = double.tryParse(maxController.text) ?? 32.0;
              await ApiService.updateThreshold('temperature', minV, maxV);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temperature limits saved')),
                );
              }
            },
            child: const Text('Save limits'),
          ),
        ],
      ),
    );
  }
}
