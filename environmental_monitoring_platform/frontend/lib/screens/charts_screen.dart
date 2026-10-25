import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/models/chart_point.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool _showTemperature = true;
  bool _liveWindowOnly = false;

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final wx = Wx.of(context);

    final now = DateTime.now();
    List<ChartPoint> displayPoints = env.historyPoints
        .where((p) => p.timestamp.difference(now).inMinutes < 5)
        .toList();
    if (_liveWindowOnly && displayPoints.isNotEmpty) {
      final cutoff = now.subtract(const Duration(minutes: 30));
      final recent =
          displayPoints.where((p) => p.timestamp.isAfter(cutoff)).toList();
      if (recent.length >= 2) {
        displayPoints = recent;
      }
    }

    double? latestIn;
    double? latestOut;
    double? latestDelta;

    if (displayPoints.isNotEmpty) {
      final last = displayPoints.last;
      latestIn =
          _showTemperature ? last.indoorTemperature : last.indoorHumidity;
      latestOut =
          _showTemperature ? last.outdoorTemperature : last.outdoorHumidity;
      if (latestIn != null && latestOut != null) {
        latestDelta = latestIn - latestOut;
      }
    }

    final unit = _showTemperature ? '°' : '%';
    final selectedDate = env.selectedDate;

    return Scaffold(
      backgroundColor: wx.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Charts',
                    style: wx.t(24, w: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.calendar_month_rounded,
                            color: wx.text, size: 22),
                        tooltip: 'Select date',
                        onPressed: () => _showCalendar(context, env),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh_rounded,
                            color: wx.text, size: 22),
                        tooltip: 'Refresh',
                        onPressed: () => env.fetchHistoryForSelectedDate(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date Capsule Strip
              _buildDateCapsuleStrip(
                env: env,
                selectedDate: selectedDate,
                wx: wx,
              ),

              const SizedBox(height: 18),

              // Dual Hero Summary
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(selectedDate),
                          style: wx.t(12, c: wx.textDim, w: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          env.outdoorReading?.city ?? 'Local Station',
                          style: wx.t(18, w: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: wx.t(42, w: FontWeight.w700, ls: -1.0),
                              children: [
                                TextSpan(
                                  text:
                                      '${latestIn != null ? latestIn.toStringAsFixed(1) : "--"}$unit',
                                  style: TextStyle(color: wx.accent),
                                ),
                                TextSpan(
                                  text:
                                      ' / ${latestOut != null ? latestOut.toStringAsFixed(1) : "--"}$unit',
                                  style: TextStyle(color: wx.outdoorLine),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestDelta != null
                              ? 'Indoor vs Outdoor · Δ${latestDelta >= 0 ? "+" : ""}${latestDelta.toStringAsFixed(1)}$unit'
                              : 'Indoor vs Outdoor comparison',
                          style: wx.t(12, c: wx.textDim),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: wx.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _showTemperature
                          ? Icons.wb_sunny_rounded
                          : Icons.water_drop_rounded,
                      size: 34,
                      color: _showTemperature
                          ? const Color(0xFFF59E0B)
                          : wx.accent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Metric / Window Pill Tabs
              Row(
                children: [
                  _buildPillChip(
                    wx: wx,
                    label: 'Temperature',
                    selected: _showTemperature,
                    onTap: () => setState(() => _showTemperature = true),
                  ),
                  const SizedBox(width: 8),
                  _buildPillChip(
                    wx: wx,
                    label: 'Humidity',
                    selected: !_showTemperature,
                    onTap: () => setState(() => _showTemperature = false),
                  ),
                  const Spacer(),
                  _buildPillChip(
                    wx: wx,
                    label: _liveWindowOnly ? '30m Live' : 'Full Day',
                    selected: _liveWindowOnly,
                    onTap: () =>
                        setState(() => _liveWindowOnly = !_liveWindowOnly),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Smooth Dual Line Chart Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: wx.card,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.ssid_chart_rounded,
                                size: 18, color: wx.text),
                            const SizedBox(width: 6),
                            Text(
                              _showTemperature ? 'Temperature' : 'Humidity',
                              style: wx.t(14, w: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildLegendDot(wx.accent, 'Indoor', wx),
                            const SizedBox(width: 12),
                            _buildLegendDot(wx.outdoorLine, 'Outdoor', wx),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 220,
                      child: displayPoints.isEmpty
                          ? Center(
                              child: Text(
                                'Awaiting telemetry records...',
                                style: wx.t(13, c: wx.textDim),
                              ),
                            )
                          : LineChart(_buildChartData(displayPoints, unit, wx)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Recent Readings Progress Bars Card
              _buildHorizontalBarsCard(
                points: displayPoints,
                unit: unit,
                wx: wx,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateCapsuleStrip({
    required EnvironmentProvider env,
    required DateTime selectedDate,
    required Wx wx,
  }) {
    final days = List.generate(
      6,
      (i) => DateTime.now().subtract(Duration(days: 5 - i)),
    );

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final d = days[idx];
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;

          return GestureDetector(
            onTap: () => env.setSelectedDate(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? wx.accent : wx.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${d.day}',
                    style: wx.t(
                      14,
                      w: FontWeight.w800,
                      c: isSelected ? wx.onAccent : wx.text,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(d),
                    style: wx.t(
                      10,
                      w: FontWeight.w500,
                      c: isSelected
                          ? wx.onAccent.withValues(alpha: 0.8)
                          : wx.textDim,
                    ),
                  ),
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 18,
                    color: isSelected
                        ? wx.onAccent
                        : const Color(0xFFF59E0B),
                  ),
                  Text(
                    DateFormat('E').format(d),
                    style: wx.t(
                      11,
                      w: FontWeight.w700,
                      c: isSelected ? wx.onAccent : wx.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillChip({
    required Wx wx,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? wx.chipOn : wx.chipOff,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: wx.t(
            12,
            w: FontWeight.w700,
            c: selected ? wx.accent : wx.textDim,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBarsCard({
    required List<ChartPoint> points,
    required String unit,
    required Wx wx,
  }) {
    final slice = points.length > 5
        ? points.sublist(points.length - 5).reversed.toList()
        : points.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: wx.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.align_horizontal_left_rounded,
                  size: 16, color: wx.text),
              const SizedBox(width: 8),
              Text(
                'Recent readings',
                style: wx.t(14, w: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (slice.isEmpty)
            Text(
              'No readings available for this date.',
              style: wx.t(12, c: wx.textDim),
            )
          else
            ...slice.map((p) {
              final val = (_showTemperature
                      ? p.indoorTemperature
                      : p.indoorHumidity) ??
                  0.0;
              final ratio = _showTemperature
                  ? (val / 45.0).clamp(0.05, 1.0)
                  : (val / 100.0).clamp(0.05, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: Text(
                        DateFormat('HH:mm').format(p.timestamp.toLocal()),
                        style: wx.t(11, w: FontWeight.w600, c: wx.textDim),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 14,
                          backgroundColor: wx.bg,
                          valueColor: AlwaysStoppedAnimation<Color>(wx.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${val.toStringAsFixed(1)}$unit',
                        textAlign: TextAlign.right,
                        style: wx.t(12, w: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, Wx wx) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: wx.t(11, w: FontWeight.w600, c: wx.textDim),
        ),
      ],
    );
  }

  LineChartData _buildChartData(
    List<ChartPoint> dynamicPoints,
    String unit,
    Wx wx,
  ) {
    final List<FlSpot> indoorSpots = [];
    final List<FlSpot> outdoorSpots = [];

    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < dynamicPoints.length; i++) {
      final p = dynamicPoints[i];
      final valIn =
          _showTemperature ? p.indoorTemperature : p.indoorHumidity;
      final valOut =
          _showTemperature ? p.outdoorTemperature : p.outdoorHumidity;

      if (valIn != null) {
        indoorSpots.add(FlSpot(i.toDouble(), valIn));
        minY = min(minY, valIn);
        maxY = max(maxY, valIn);
      }
      if (valOut != null) {
        outdoorSpots.add(FlSpot(i.toDouble(), valOut));
        minY = min(minY, valOut);
        maxY = max(maxY, valOut);
      }
    }

    if (minY == double.infinity) minY = 0;
    if (maxY == -double.infinity) maxY = 50;

    final diff = maxY - minY;
    final padding = diff > 2.0 ? diff * 0.18 : 1.5;
    minY = (minY - padding).floorToDouble();
    maxY = (maxY + padding).ceilToDouble();
    if (minY < 0 && !_showTemperature) minY = 0;

    final yInterval = ((maxY - minY) / 3).clamp(0.5, 20.0);

    return LineChartData(
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => wx.card,
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isIndoor = spot.barIndex == 0;
              return LineTooltipItem(
                '${isIndoor ? "Indoor" : "Outdoor"}: ${spot.y.toStringAsFixed(1)}$unit',
                TextStyle(
                  color: isIndoor ? wx.accent : wx.outdoorLine,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: wx.textDim.withValues(alpha: 0.12),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: yInterval,
            getTitlesWidget: (val, _) => Text(
              '${val.toInt()}$unit',
              style: wx.t(10, w: FontWeight.w600, c: wx.textDim),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: max(1.0, (dynamicPoints.length / 4).floorToDouble()),
            getTitlesWidget: (val, _) {
              final idx = val.toInt();
              if (idx >= 0 && idx < dynamicPoints.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('HH:mm')
                        .format(dynamicPoints[idx].timestamp.toLocal()),
                    style: wx.t(10, w: FontWeight.w600, c: wx.textDim),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: indoorSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: wx.accent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                wx.accent.withValues(alpha: 0.3),
                wx.accent.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        LineChartBarData(
          spots: outdoorSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: wx.outdoorLine,
          barWidth: 2.2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  void _showCalendar(BuildContext context, EnvironmentProvider env) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: env.selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      env.setSelectedDate(picked);
    }
  }
}
