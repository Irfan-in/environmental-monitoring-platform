import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/models/alert_item.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/services/api_service.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _filter = 0; // 0 = active, 1 = acknowledged, 2 = all

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final wx = Wx.of(context);

    final all = env.alerts;
    final activeCount = all.where((a) => !a.isAcknowledged).length;
    final shown = all.where((a) {
      if (_filter == 0) return !a.isAcknowledged;
      if (_filter == 1) return a.isAcknowledged;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: wx.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Alerts', style: wx.t(24, w: FontWeight.w500)),
                ),
                IconButton(
                  tooltip: 'Acknowledge all alerts',
                  icon: Icon(Icons.done_all, color: wx.good),
                  onPressed: () async {
                    await env.acknowledgeAllAlerts();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All alerts acknowledged')),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Set thresholds',
                  icon: Icon(Icons.tune, color: wx.text),
                  onPressed: () => _showThresholdDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Big readout
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$activeCount',
                          style: wx.t(64, w: FontWeight.w300, h: 1.05)),
                      Text(
                        activeCount == 0
                            ? 'Everything is within limits'
                            : (activeCount == 1 ? 'active alert' : 'active alerts'),
                        style: wx.t(14, c: wx.textDim),
                      ),
                    ],
                  ),
                ),
                if (activeCount == 0)
                  const WeatherGlyph(code: 0, size: 72)
                else
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: wx.bad.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, size: 40, color: wx.bad),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            WxChips(
              labels: const ['Active', 'Acknowledged', 'All'],
              index: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),
            const SizedBox(height: 12),

            if (shown.isEmpty)
              WxCard(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    WxIconDot(icon: Icons.check_circle_outline, size: 56, color: wx.good),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 1
                          ? 'No acknowledged alerts'
                          : 'All readings are normal',
                      style: wx.t(16, w: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _filter == 1
                          ? 'Alerts you acknowledge will show up here.'
                          : 'No thresholds have been crossed.',
                      textAlign: TextAlign.center,
                      style: wx.t(13, c: wx.textDim),
                    ),
                  ],
                ),
              )
            else
              for (final alert in shown) ...[
                _alertCard(wx, env, alert),
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

  Widget _alertCard(Wx wx, EnvironmentProvider env, AlertItem alert) {
    final acked = alert.isAcknowledged;
    final tone = acked ? wx.good : wx.bad;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: wx.card,
        borderRadius: BorderRadius.circular(24),
        border: acked
            ? null
            : Border.all(color: wx.bad.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _pretty(alert.alertType),
                    style: wx.t(11, w: FontWeight.w600, c: tone),
                  ),
                ),
                const SizedBox(height: 8),
                Text(alert.message, style: wx.t(15, w: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  '${alert.source}  \u00B7  ${DateFormat('HH:mm:ss').format(alert.timestamp)}',
                  style: wx.t(12, c: wx.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 48,
            color: wx.textDim.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_num(alert.triggeredValue),
                  style: wx.t(18, w: FontWeight.w500, c: acked ? wx.text : wx.bad)),
              const SizedBox(height: 2),
              Text('Limit ${_num(alert.thresholdValue)}',
                  style: wx.t(11, c: wx.textDim)),
            ],
          ),
          if (!acked)
            IconButton(
              tooltip: 'Acknowledge',
              icon: Icon(Icons.done, color: wx.accent),
              onPressed: () => env.acknowledgeAlert(alert.id),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── threshold dialog (admin only, unchanged behaviour) ─────────────────────

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
            'Only administrators can change thresholds.\n\n'
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
