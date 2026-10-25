import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../models/chart_point.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  bool _showTemperature = true; // true = Temperature (°C), false = Relative Humidity (%)
  bool _liveWindowOnly = false; // true = Last 30 mins (High-Res), false = Full Day

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    // Filter points based on mode and ensure no future-skewed entries
    List<ChartPoint> displayPoints = env.historyPoints.where((p) => p.timestamp.difference(now).inMinutes < 5).toList();
    if (_liveWindowOnly && displayPoints.isNotEmpty) {
      final cutoff = now.subtract(const Duration(minutes: 30));
      final recent = displayPoints.where((p) => p.timestamp.isAfter(cutoff)).toList();
      if (recent.length >= 2) {
        displayPoints = recent;
      }
    }

    // Dynamic stats
    double? maxIn;
    double? minIn;
    double? maxOut;
    double? minOut;
    double? latestDelta;

    for (final p in displayPoints) {
      final valIn = _showTemperature ? p.indoorTemperature : p.indoorHumidity;
      final valOut = _showTemperature ? p.outdoorTemperature : p.outdoorHumidity;

      if (valIn != null) {
        maxIn = maxIn == null ? valIn : max(maxIn, valIn);
        minIn = minIn == null ? valIn : min(minIn, valIn);
      }
      if (valOut != null) {
        maxOut = maxOut == null ? valOut : max(maxOut, valOut);
        minOut = minOut == null ? valOut : min(minOut, valOut);
      }
    }

    if (displayPoints.isNotEmpty) {
      final last = displayPoints.last;
      final inVal = _showTemperature ? last.indoorTemperature : last.indoorHumidity;
      final outVal = _showTemperature ? last.outdoorTemperature : last.outdoorHumidity;
      if (inVal != null && outVal != null) {
        latestDelta = inVal - outVal;
      }
    }

    final unit = _showTemperature ? '°C' : '%';
    final selectedDate = env.selectedDate;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparative Telemetry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Real-time Stream (Dual Trace)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: 'Select Archive Date',
            onPressed: () => _showCalendar(context, env),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: 'Refresh Telemetry',
            onPressed: () => env.fetchHistoryForSelectedDate(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Navigator Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    onPressed: () => env.goToPreviousDay(),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showCalendar(context, env),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (env.isSelectedDateToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE TODAY',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    color: env.isSelectedDateToday
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    onPressed: env.isSelectedDateToday ? null : () => env.goToNextDay(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Control Chips (Metric selector + Window mode)
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Temperature (°C)'),
                  selected: _showTemperature,
                  selectedColor: const Color(0xFF38BDF8),
                  backgroundColor: theme.cardColor,
                  labelStyle: TextStyle(
                    color: _showTemperature ? const Color(0xFF0F172A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _showTemperature = true);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Humidity (%)'),
                  selected: !_showTemperature,
                  selectedColor: const Color(0xFF34D399),
                  backgroundColor: theme.cardColor,
                  labelStyle: TextStyle(
                    color: !_showTemperature ? const Color(0xFF0F172A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _showTemperature = false);
                  },
                ),
                const Spacer(),
                FilterChip(
                  label: Text(_liveWindowOnly ? '30m Window' : 'Full Day'),
                  selected: _liveWindowOnly,
                  onSelected: (val) => setState(() => _liveWindowOnly = val),
                  avatar: Icon(
                    _liveWindowOnly ? Icons.timelapse : Icons.history,
                    size: 14,
                    color: _liveWindowOnly ? const Color(0xFF0F172A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Telemetry KPI Highlights Strip (Dual Point Delta)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    context: context,
                    title: 'Indoor Node',
                    value: displayPoints.isNotEmpty &&
                            (_showTemperature
                                    ? displayPoints.last.indoorTemperature
                                    : displayPoints.last.indoorHumidity) !=
                                null
                        ? '${(_showTemperature ? displayPoints.last.indoorTemperature! : displayPoints.last.indoorHumidity!).toStringAsFixed(1)}$unit'
                        : '--',
                    color: const Color(0xFF38BDF8),
                    icon: Icons.sensors,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    context: context,
                    title: 'Outdoor Ref',
                    value: displayPoints.isNotEmpty &&
                            (_showTemperature
                                    ? displayPoints.last.outdoorTemperature
                                    : displayPoints.last.outdoorHumidity) !=
                                null
                        ? '${(_showTemperature ? displayPoints.last.outdoorTemperature! : displayPoints.last.outdoorHumidity!).toStringAsFixed(1)}$unit'
                        : '--',
                    color: const Color(0xFFFB923C),
                    icon: Icons.cloud_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKpiCard(
                    context: context,
                    title: 'Delta (Δ)',
                    value: latestDelta != null
                        ? '${latestDelta >= 0 ? '+' : ''}${latestDelta.toStringAsFixed(1)}$unit'
                        : '--',
                    color: (latestDelta != null && latestDelta < 0)
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFFFB923C),
                    icon: Icons.linear_scale,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 4. Main Telemetry Graph Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showTemperature
                            ? 'Differential Temperature Profile'
                            : 'Differential Humidity Profile',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xFF38BDF8), 'Indoor (ESP32)', isDark),
                          const SizedBox(width: 10),
                          _buildLegendDot(const Color(0xFFFB923C), 'Outdoor Ambient', isDark),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stored permanently on local device • ${displayPoints.length} points plotted',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart Canvas
                  SizedBox(
                    height: 270,
                    child: displayPoints.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_graph_outlined, size: 36, color: Color(0xFF64748B)),
                                const SizedBox(height: 8),
                                Text(
                                  'Archiving telemetry records locally...',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : LineChart(_buildChartData(displayPoints, unit, isDark)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Interactive Tooltip Hint
            Center(
              child: Text(
                'Touch and hold anywhere on the curve to inspect synchronized dual-point delta values.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<ChartPoint> dynamicPoints, String unit, bool isDark) {
    final List<FlSpot> indoorSpots = [];
    final List<FlSpot> outdoorSpots = [];

    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i < dynamicPoints.length; i++) {
      final p = dynamicPoints[i];
      final valIn = _showTemperature ? p.indoorTemperature : p.indoorHumidity;
      final valOut = _showTemperature ? p.outdoorTemperature : p.outdoorHumidity;

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

    // High sensitivity Y-axis bounds: Give enough padding to see even 0.1°C fluctuations clearly
    final diff = maxY - minY;
    final padding = diff > 2.0 ? diff * 0.15 : 1.0;
    minY = (minY - padding).floorToDouble();
    maxY = (maxY + padding).ceilToDouble();
    if (minY < 0 && !_showTemperature) minY = 0;

    final yInterval = ((maxY - minY) / 4).clamp(0.5, 20.0);

    return LineChartData(
      minY: minY,
      maxY: maxY,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => isDark ? const Color(0xFF0F172A) : Colors.white,
          tooltipBorder: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            final idx = touchedSpots.first.spotIndex;
            final point = (idx >= 0 && idx < dynamicPoints.length) ? dynamicPoints[idx] : null;
            final timeStr = point != null ? DateFormat('HH:mm:ss').format(point.timestamp.toLocal()) : '';

            // Calculate instantaneous delta
            final inVal = _showTemperature ? point?.indoorTemperature : point?.indoorHumidity;
            final outVal = _showTemperature ? point?.outdoorTemperature : point?.outdoorHumidity;
            final deltaStr = (inVal != null && outVal != null)
                ? 'Δ: ${(inVal - outVal) >= 0 ? '+' : ''}${(inVal - outVal).toStringAsFixed(1)}$unit'
                : '';

            return touchedSpots.map((spot) {
              final isIndoor = spot.barIndex == 0;
              final label = isIndoor ? 'Indoor' : 'Outdoor';

              return LineTooltipItem(
                isIndoor ? '$timeStr\n$label: ${spot.y.toStringAsFixed(1)}$unit  [$deltaStr]' : '$label: ${spot.y.toStringAsFixed(1)}$unit',
                TextStyle(
                  color: isIndoor ? const Color(0xFF38BDF8) : const Color(0xFFFB923C),
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
        getDrawingHorizontalLine: (val) => FlLine(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
          strokeWidth: 0.8,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: yInterval,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 9,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: max(1.0, (dynamicPoints.length / 4).floorToDouble()),
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < dynamicPoints.length) {
                final p = dynamicPoints[idx];
                return Text(
                  DateFormat('HH:mm').format(p.timestamp.toLocal()),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 9,
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
        // Trace 1: Indoor Microclimate (Cyan / Electric Blue)
        LineChartBarData(
          spots: indoorSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xFF38BDF8),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF38BDF8).withValues(alpha: 0.25),
                const Color(0xFF38BDF8).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Trace 2: Outdoor Ambient (Sunset Amber / Orange)
        LineChartBarData(
          spots: outdoorSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: const Color(0xFFFB923C),
          barWidth: 2.0,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFB923C).withValues(alpha: 0.15),
                const Color(0xFFFB923C).withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      env.setSelectedDate(picked);
    }
  }
}
