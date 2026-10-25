import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/models/chart_point.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/services/api_service.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _view = 0; // 0 = indoor, 1 = outdoor, 2 = compare

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final wx = Wx.of(context);
    final points = _todayPoints(env);
    final advisory = env.activeClimateAdvisory;

    return Scaffold(
      backgroundColor: wx.bg,
      body: RefreshIndicator(
        onRefresh: () => env.fetchData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _Hero(
              env: env,
              onAccount: () => _showLoginSheet(context, env),
              onSettings: () => _showSettingsSheet(context, env),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                children: [
                  if (advisory != null) ...[
                    _advisoryBanner(wx, env, advisory),
                    const SizedBox(height: 12),
                  ],
                  WxChips(
                    labels: const ['Indoor', 'Outdoor'],
                    index: _view.clamp(0, 1),
                    onChanged: (i) => setState(() => _view = i),
                  ),
                  const SizedBox(height: 12),
                  _tileGrid(_tiles(env, points)),
                  const SizedBox(height: 12),
                  _trendCard(wx, env, points),
                  const SizedBox(height: 12),
                  _humidityCard(wx, env),
                  const SizedBox(height: 12),
                  _footerTiles(env),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── data helpers ───────────────────────────────────────────────────────────

  List<ChartPoint> _todayPoints(EnvironmentProvider env) {
    if (!env.isSelectedDateToday) return const [];
    final now = DateTime.now();
    return env.historyPoints
        .where((p) => p.timestamp.difference(now).inMinutes < 5)
        .toList();
  }

  double? _change(List<ChartPoint> pts, double? Function(ChartPoint) pick) {
    double? first;
    double? last;
    for (final p in pts) {
      final v = pick(p);
      if (v == null) continue;
      first ??= v;
      last = v;
    }
    if (first == null || last == null) return null;
    final d = last - first;
    return d.abs() < 0.05 ? null : d;
  }

  String _ago(DateTime? t) {
    if (t == null) return '--';
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 5) return 'Just now';
    if (s < 60) return '${s}s ago';
    if (s < 3600) return '${s ~/ 60}m ago';
    return '${s ~/ 3600}h ago';
  }



  // ── sections ───────────────────────────────────────────────────────────────

  Widget _advisoryBanner(Wx wx, EnvironmentProvider env, String message) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: wx.warnBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: wx.warn, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: wx.t(13, w: FontWeight.w500, c: wx.warn)),
          ),
          TextButton(
            onPressed: env.dismissAdvisory,
            child: Text('Dismiss',
                style: wx.t(13, w: FontWeight.w600, c: wx.warn)),
          ),
        ],
      ),
    );
  }

  List<WxTile> _tiles(EnvironmentProvider env, List<ChartPoint> pts) {
    final live = env.isEsp32Online ? env.indoorReading : null;
    final out = env.outdoorReading;
    String deg(num? v) => v == null ? '--' : '${v.toStringAsFixed(1)}°';
    String pct(num? v) => v == null ? '--' : '${v.toStringAsFixed(0)}%';
    String sg(num? v, String u) =>
        v == null ? '--' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}$u';

    switch (_view) {
      case 1:
        return [
          WxTile(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: deg(out?.temperature),
            delta: _change(pts, (p) => p.outdoorTemperature),
            deltaUnit: '°',
          ),
          WxTile(
            icon: Icons.water_drop_outlined,
            label: 'Humidity',
            value: pct(out?.humidity),
            delta: _change(pts, (p) => p.outdoorHumidity),
            deltaUnit: '%',
          ),
          WxTile(
            icon: Icons.air,
            label: 'Wind',
            value: out == null ? '--' : '${out.windSpeed.toStringAsFixed(1)} km/h',
          ),
          WxTile(
            icon: out?.isCached == true
                ? Icons.cloud_off_outlined
                : Icons.cloud_done_outlined,
            label: 'Weather data',
            value: out == null ? '--' : (out.isCached == true ? 'Cached' : 'Live'),
          ),
        ];
      case 2:
        final dT = env.comparisonData?.tempDiff;
        final dH = (live != null && out != null) ? live.humidity - out.humidity : null;
        return [
          WxTile(icon: Icons.swap_vert, label: 'Temp gap', value: sg(dT, '°')),
          WxTile(icon: Icons.water_drop_outlined, label: 'Humidity gap', value: sg(dH, '%')),
          WxTile(
            icon: Icons.sentiment_satisfied_alt_outlined,
            label: 'Comfort',
            value: env.comparisonData?.comfortAssessment ?? 'Optimal',
          ),
          WxTile(
            icon: Icons.storage_outlined,
            label: 'Saved readings',
            value: '${env.localRecordCount}',
          ),
        ];
      default:
        final feels =
            live == null ? null : Wx.feelsLike(live.temperature, live.humidity);
        return [
          WxTile(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: deg(live?.temperature),
            delta: _change(pts, (p) => p.indoorTemperature),
            deltaUnit: '°',
          ),
          WxTile(
            icon: Icons.water_drop_outlined,
            label: 'Humidity',
            value: pct(live?.humidity),
            delta: _change(pts, (p) => p.indoorHumidity),
            deltaUnit: '%',
          ),
          WxTile(icon: Icons.device_thermostat, label: 'Feels like', value: deg(feels)),
          WxTile(
            icon: Icons.schedule,
            label: 'Updated',
            value: _ago(env.indoorReading?.timestamp),
          ),
        ];
    }
  }

  Widget _tileGrid(List<WxTile> t) => Column(
        children: [
          Row(children: [
            Expanded(child: t[0]),
            const SizedBox(width: 8),
            Expanded(child: t[1]),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: t[2]),
            const SizedBox(width: 8),
            Expanded(child: t[3]),
          ]),
        ],
      );

  Widget _archiveNote(Wx wx, EnvironmentProvider env) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Showing ${DateFormat('d MMM').format(env.selectedDate)}. '
          'Switch back to see today’s live readings.',
          style: wx.t(13, c: wx.textDim),
        ),
        TextButton(
          onPressed: env.resetToToday,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text('Back to today',
              style: wx.t(13, w: FontWeight.w600, c: wx.accent)),
        ),
      ],
    );
  }



  Widget _trendCard(Wx wx, EnvironmentProvider env, List<ChartPoint> pts) {
    final title = _view == 0 ? 'Indoor trend' : 'Outdoor trend';
    return WxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WxCardTitle(icon: Icons.show_chart, title: title),
          const SizedBox(height: 16),
          if (!env.isSelectedDateToday)
            _archiveNote(wx, env)
          else ...[
            WxTrendChart(
              points: pts,
              temperature: true,
              showIndoor: _view == 0,
              showOutdoor: _view == 1,
              height: 170,
            ),
          ],
        ],
      ),
    );
  }

  Widget _humidityCard(Wx wx, EnvironmentProvider env) {
    final live = env.isEsp32Online ? env.indoorReading : null;
    final out = env.outdoorReading;
    final inH = live?.humidity;
    final outH = out?.humidity;

    String hint = 'Waiting for sensor.';
    if (inH != null) {
      if (inH > 70) {
        hint = 'High humidity. Airflow recommended.';
      } else if (inH < 30) {
        hint = 'Dry air. Humidifier recommended.';
      } else {
        hint = 'Comfortable humidity level.';
      }
    }

    return WxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WxCardTitle(icon: Icons.water_drop_outlined, title: 'Humidity'),
          const SizedBox(height: 14),
          Row(
            children: [
              WxWaveGauge(percent: inH?.toDouble(), caption: 'Indoor'),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WxBarRow(
                      label: 'Indoor',
                      fraction: inH == null ? null : inH / 100,
                      valueText: inH == null ? '--' : '${inH.toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 12),
                    WxBarRow(
                      label: 'Outdoor',
                      fraction: outH == null ? null : outH / 100,
                      valueText: outH == null ? '--' : '${outH.toStringAsFixed(0)}%',
                      color: wx.outdoorLine,
                    ),
                    const SizedBox(height: 12),
                    Text(hint, style: wx.t(12, c: wx.textDim)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerTiles(EnvironmentProvider env) {
    final live = env.isEsp32Online ? env.indoorReading : null;
    return Row(
      children: [
        Expanded(
          child: WxInfoTile(
            icon: Icons.sensors,
            label: 'Sensor',
            value: env.isEsp32Online ? 'Online' : 'Offline',
            caption: live == null
                ? 'ESP32 Node'
                : DateFormat('HH:mm:ss').format(live.timestamp.toLocal()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: WxInfoTile(
            icon: Icons.storage_outlined,
            label: 'Local storage',
            value: '${env.localRecordCount}',
            caption: 'saved records',
          ),
        ),
      ],
    );
  }

  // ── sheets ─────────────────────────────────────────────────────────────────

  Widget _themeChip(
    Wx wx,
    EnvironmentProvider env,
    StateSetter setSheet,
    String label,
    ThemeMode mode,
  ) {
    final selected = env.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          env.setThemeMode(mode);
          setSheet(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? wx.accent : wx.iconBg,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? null
                : Border.all(color: wx.textDim.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mode == ThemeMode.system
                    ? Icons.brightness_auto_outlined
                    : (mode == ThemeMode.light
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined),
                color: selected ? wx.onAccent : wx.textDim,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: wx.t(
                  12,
                  w: FontWeight.w600,
                  c: selected ? wx.onAccent : wx.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, EnvironmentProvider env) {
    final wx = Wx.of(context);
    final serverController = TextEditingController(text: ApiService.baseUrl);

    showWxSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final off = env.temperatureOffset;
          final offText = '${off >= 0 ? '+' : ''}${off.toStringAsFixed(1)}°C';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: wx.t(22, w: FontWeight.w500)),
              const SizedBox(height: 16),
              Text('Theme', style: wx.t(14, w: FontWeight.w600, c: wx.accent)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _themeChip(wx, env, setSheet, 'System', ThemeMode.system),
                  const SizedBox(width: 8),
                  _themeChip(wx, env, setSheet, 'Light', ThemeMode.light),
                  const SizedBox(width: 8),
                  _themeChip(wx, env, setSheet, 'Dark', ThemeMode.dark),
                ],
              ),
              const SizedBox(height: 16),
              Text('Accent Color', style: wx.t(14, w: FontWeight.w600, c: wx.accent)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WxAccentTheme.values.map((t) {
                  final isSelected = env.accentTheme == t;
                  return InkWell(
                    onTap: () {
                      env.setAccentTheme(t);
                      setSheet(() {});
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? t.color.withValues(alpha: 0.28) : wx.chipOff,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? t.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: t.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t.label,
                            style: wx.t(
                              12,
                              w: isSelected ? FontWeight.w600 : FontWeight.w400,
                              c: isSelected ? t.color : wx.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (!env.isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: wx.iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sign in for sensor calibration & gateway settings.',
                          style: wx.t(12, c: wx.textDim),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showLoginSheet(context, env);
                        },
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Temperature calibration',
                        style: wx.t(14, w: FontWeight.w600, c: wx.accent)),
                    Text(offText, style: wx.t(14, w: FontWeight.w500)),
                  ],
                ),
                Slider(
                  value: off,
                  min: -5,
                  max: 5,
                  divisions: 20,
                  label: offText,
                  onChanged: (v) {
                    env.setTemperatureOffset(v);
                    setSheet(() {});
                  },
                ),
                const SizedBox(height: 8),
                Text('Gateway URL',
                    style: wx.t(14, w: FontWeight.w600, c: wx.accent)),
                const SizedBox(height: 8),
                TextField(
                  controller: serverController,
                  style: wx.t(13),
                  decoration: wx.field('Gateway URL', hint: 'https://...').copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save_outlined, size: 20),
                      tooltip: 'Save gateway URL',
                      onPressed: () {
                        ApiService.setBaseUrl(serverController.text.trim());
                        env.fetchData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gateway URL saved')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Storage',
                    style: wx.t(14, w: FontWeight.w600, c: wx.accent)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: wx.outlineButton(wx.text),
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Clear'),
                        onPressed: () async {
                          await env.clearLocalStorage();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved readings cleared')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: wx.filledButton,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Sync'),
                        onPressed: () async {
                          await env.fetchData();
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Latest readings fetched')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout, color: wx.bad),
                  title: Text('Log out (${env.username})',
                      style: wx.t(14, w: FontWeight.w500, c: wx.bad)),
                  onTap: () {
                    Navigator.pop(ctx);
                    env.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out. Switched to guest mode.')),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showLoginSheet(BuildContext context, EnvironmentProvider env) {
    final wx = Wx.of(context);
    final userController = TextEditingController(text: 'irfan');
    final passController = TextEditingController(text: '1234');
    String? authError;

    showWxSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                WxIconDot(
                  icon: env.isLoggedIn
                      ? Icons.account_circle
                      : Icons.account_circle_outlined,
                  size: 44,
                  color: env.isLoggedIn ? wx.good : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    env.isLoggedIn ? env.username : 'Account',
                    style: wx.t(22, w: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              env.isLoggedIn
                  ? 'Signed in.'
                  : 'Sign in to access calibration and cloud settings.',
              style: wx.t(13, c: wx.textDim),
            ),
            const SizedBox(height: 18),
            if (env.isLoggedIn)
              OutlinedButton.icon(
                style: wx.outlineButton(wx.bad),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Log out'),
                onPressed: () async {
                  await env.logout();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out. Switched to guest mode.')),
                    );
                  }
                },
              )
            else ...[
              if (authError != null) ...[
                Text(authError!, style: wx.t(13, c: wx.bad)),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: userController,
                decoration: wx.field('Username', icon: Icons.person_outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: wx.field('Password', icon: Icons.lock_outline),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: wx.filledButton,
                onPressed: () async {
                  final err = await env.login(
                    userController.text.trim(),
                    passController.text.trim(),
                  );
                  if (err != null) {
                    setSheet(() => authError = err);
                    return;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Welcome, ${env.username}')),
                    );
                  }
                },
                child: const Text('Log in'),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text('Demo: irfan / 1234 or admin / admin123',
                    style: wx.t(12, c: wx.textDim)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero card — big temperature on a dusk-purple gradient
// ─────────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({
    required this.env,
    required this.onAccount,
    required this.onSettings,
  });
  final EnvironmentProvider env;
  final VoidCallback onAccount;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    final top = MediaQuery.of(context).padding.top;
    final live = env.isEsp32Online ? env.indoorReading : null;
    final out = env.outdoorReading;
    const white = Colors.white;
    final soft = Colors.white.withValues(alpha: 0.78);

    final big = live == null ? '--' : live.temperature.toStringAsFixed(1);
    final feels = live == null
        ? 'Waiting for sensor'
        : 'Feels like ${Wx.feelsLike(live.temperature, live.humidity).toStringAsFixed(1)}°';

    return Container(
      margin: EdgeInsets.fromLTRB(8, top + 8, 8, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: wx.heroColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            const Positioned.fill(child: WxSparkle()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              out?.city ?? 'Local Station',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: wx.t(20, w: FontWeight.w500, c: white),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: live != null
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFFFFB4AB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  live != null
                                      ? 'Sensor live'
                                      : 'Sensor offline',
                                  style: wx.t(12, c: soft),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: env.isLoggedIn ? 'Account' : 'Log in',
                        onPressed: onAccount,
                        icon: Icon(
                          env.isLoggedIn
                              ? Icons.account_circle
                              : Icons.account_circle_outlined,
                          color: white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: onSettings,
                        icon: const Icon(Icons.settings_outlined, color: white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(big,
                                        style: wx.t(88,
                                            w: FontWeight.w300, c: white, h: 1.05)),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text('°',
                                          style: wx.t(40, w: FontWeight.w300, c: white)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(feels, style: wx.t(15, c: white)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            WeatherGlyph(code: out?.weatherCode ?? 1, size: 100),
                            const SizedBox(height: 3),
                            Builder(
                              builder: (_) {
                                final t = out?.temperature;
                                final outTemp = t != null
                                    ? '${t.toStringAsFixed(t.truncateToDouble() == t ? 0 : 1)}°C'
                                    : '--';
                                final cleanDesc = (out?.weatherDesc ?? '--')
                                    .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
                                    .trim();
                                return Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$outTemp  ',
                                        style: wx.t(13, w: FontWeight.w700, c: white),
                                      ),
                                      TextSpan(
                                        text: cleanDesc,
                                        style: wx.t(12, w: FontWeight.w400, c: soft),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
