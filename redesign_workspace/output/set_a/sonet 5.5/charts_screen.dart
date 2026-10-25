import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chart_point.dart';
import '../providers/environment_provider.dart';
import '../theme/wx_style.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool _showTemperature = true; // false = relative humidity
  bool _liveWindowOnly = false; // true = last 30 minutes

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final wx = Wx.of(context);

    final now = DateTime.now();
    List<ChartPoint> pts = env.historyPoints
        .where((p) => p.timestamp.difference(now).inMinutes < 5)
        .toList();
    if (_liveWindowOnly && pts.isNotEmpty) {
      final recent = pts
          .where((p) => p.timestamp.isAfter(now.subtract(const Duration(minutes: 30))))
          .toList();
      if (recent.length >= 2) pts = recent;
    }

    double? minIn, maxIn, minOut, maxOut;
    for (final p in pts) {
      final double? a = _showTemperature ? p.indoorTemperature : p.indoorHumidity;
      final double? b = _showTemperature ? p.outdoorTemperature : p.outdoorHumidity;
      if (a != null) {
        minIn = minIn == null ? a : min(minIn, a);
        maxIn = maxIn == null ? a : max(maxIn, a);
      }
      if (b != null) {
        minOut = minOut == null ? b : min(minOut, b);
        maxOut = maxOut == null ? b : max(maxOut, b);
      }
    }

    double? latestIn, latestOut;
    if (pts.isNotEmpty) {
      final last = pts.last;
      latestIn = _showTemperature ? last.indoorTemperature : last.indoorHumidity;
      latestOut = _showTemperature ? last.outdoorTemperature : last.outdoorHumidity;
    }
    final delta = (latestIn != null && latestOut != null) ? latestIn - latestOut : null;
    final unit = _showTemperature ? '°' : '%';
    String fmt(double? v) => v == null ? '--' : v.toStringAsFixed(1);
    String signed(double? v) =>
        v == null ? '--' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}$unit';

    return Scaffold(
      backgroundColor: wx.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trends', style: wx.t(24, w: FontWeight.w500)),
                      Text('Indoor sensor and outdoor weather',
                          style: wx.t(13, c: wx.textDim)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pick a date',
                  icon: Icon(Icons.calendar_month_outlined, color: wx.text),
                  onPressed: () => _showCalendar(context, env),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: Icon(Icons.refresh, color: wx.text),
                  onPressed: env.fetchHistoryForSelectedDate,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmt(latestIn),
                              style: wx.t(64, w: FontWeight.w300, h: 1.05)),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(unit, style: wx.t(28, w: FontWeight.w300)),
                          ),
                        ],
                      ),
                      Text(
                        'Outdoor ${fmt(latestOut)}$unit   Gap ${signed(delta)}',
                        style: wx.t(14, c: wx.textDim),
                      ),
                    ],
                  ),
                ),
                WeatherGlyph(code: env.outdoorReading?.weatherCode ?? 1, size: 72),
              ],
            ),
            const SizedBox(height: 16),

            // Date navigator as chips
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: WxChipButton(
                    onTap: env.goToPreviousDay,
                    child: Icon(Icons.chevron_left, color: wx.text),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: WxChipButton(
                    selected: true,
                    onTap: () => _showCalendar(context, env),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(env.selectedDate),
                          style: wx.t(14, w: FontWeight.w500, c: wx.accent),
                        ),
                        if (env.isSelectedDateToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: wx.good,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('Live', style: wx.t(12, w: FontWeight.w500, c: wx.good)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: WxChipButton(
                    onTap: env.isSelectedDateToday ? null : env.goToNextDay,
                    child: Icon(Icons.chevron_right, color: wx.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            WxChips(
              labels: const ['Temperature', 'Humidity'],
              index: _showTemperature ? 0 : 1,
              onChanged: (i) => setState(() => _showTemperature = i == 0),
            ),
            const SizedBox(height: 12),

            // Chart card
            WxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WxCardTitle(
                    icon: Icons.show_chart,
                    title: _showTemperature ? 'Temperature profile' : 'Humidity profile',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          WxLegendDot(color: wx.accent, label: 'Indoor'),
                          const SizedBox(width: 14),
                          WxLegendDot(color: wx.outdoorLine, label: 'Outdoor'),
                        ],
                      ),
                      WxSegment(
                        labels: const ['30 min', 'Full day'],
                        index: _liveWindowOnly ? 0 : 1,
                        onChanged: (i) => setState(() => _liveWindowOnly = i == 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WxTrendChart(
                    points: pts,
                    temperature: _showTemperature,
                    height: 240,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pts.length} readings, saved on this phone. Touch the chart to compare a moment.',
                    style: wx.t(11, c: wx.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Range card
            WxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WxCardTitle(icon: Icons.swap_vert, title: 'Range'),
                  const SizedBox(height: 16),
                  _rangeRow(wx, 'Indoor', minIn, maxIn, minOut, maxOut, wx.accent, unit),
                  const SizedBox(height: 14),
                  _rangeRow(wx, 'Outdoor', minOut, maxOut, minIn, maxIn, wx.outdoorLine, unit),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: WxInfoTile(
                    icon: Icons.swap_vert,
                    label: 'Indoor minus outdoor',
                    value: signed(delta),
                    caption: 'Latest reading',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: WxInfoTile(
                    icon: Icons.storage_outlined,
                    label: 'Readings plotted',
                    value: '${pts.length}',
                    caption: _liveWindowOnly ? 'Last 30 min' : 'Full day',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One pill track with the min–max span highlighted. [otherMin]/[otherMax]
  /// widen the shared scale so both rows are directly comparable.
  Widget _rangeRow(Wx wx, String label, double? lo, double? hi, double? otherMin,
      double? otherMax, Color color, String unit) {
    final scaleLo = [lo, otherMin].whereType<double>().fold<double?>(
        null, (a, b) => a == null ? b : min(a, b));
    final scaleHi = [hi, otherMax].whereType<double>().fold<double?>(
        null, (a, b) => a == null ? b : max(a, b));

    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: wx.t(13))),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final track = Container(
                height: 16,
                decoration: BoxDecoration(
                  color: wx.accentTrack,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
              if (lo == null || hi == null || scaleLo == null || scaleHi == null) {
                return track;
              }
              final span = (scaleHi - scaleLo) <= 0 ? 1.0 : scaleHi - scaleLo;
              final width = max(12.0, (hi - lo) / span * c.maxWidth);
              final left = ((lo - scaleLo) / span * c.maxWidth)
                  .clamp(0.0, max(0.0, c.maxWidth - width))
                  .toDouble();
              return SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned.fill(child: track),
                    Positioned(
                      left: left,
                      width: width,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: Text(
            (lo == null || hi == null)
                ? '--'
                : '${lo.toStringAsFixed(1)} to ${hi.toStringAsFixed(1)}$unit',
            textAlign: TextAlign.right,
            style: wx.t(12, c: wx.textDim),
          ),
        ),
      ],
    );
  }

  Future<void> _showCalendar(BuildContext context, EnvironmentProvider env) async {
    final wx = Wx.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: env.selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: wx.accent,
                onPrimary: wx.onAccent,
                surface: wx.bg,
                onSurface: wx.text,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) env.setSelectedDate(picked);
  }
}
