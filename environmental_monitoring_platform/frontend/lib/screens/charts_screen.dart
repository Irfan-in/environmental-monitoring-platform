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
  bool _showTemperature = true; // true = temp, false = hum

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final points = env.historyPoints;
    final selectedDate = env.selectedDate;

    // Calculate dynamic stats
    double? maxIn;
    double? minIn;
    double? maxOut;
    double? minOut;
    double? latestDelta;

    for (final p in points) {
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

    if (points.isNotEmpty) {
      final last = points.last;
      final inVal = _showTemperature ? last.indoorTemperature : last.indoorHumidity;
      final outVal = _showTemperature ? last.outdoorTemperature : last.outdoorHumidity;
      if (inVal != null && outVal != null) {
        latestDelta = inVal - outVal;
      }
    }

    final unit = _showTemperature ? '°C' : '%';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Text(
          'Diurnal History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Realme-style top Calendar Icon
          IconButton(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 24,
            ),
            tooltip: 'Choose Date',
            onPressed: () => _showRealmeCalendar(context, env),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Realme-Style Date Navigator Strip: < 18 Oct 2026 >
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 26),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    tooltip: 'Previous Day',
                    onPressed: () => env.goToPreviousDay(),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showRealmeCalendar(context, env),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (env.isSelectedDateToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
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
                    icon: const Icon(Icons.chevron_right, size: 26),
                    color: env.isSelectedDateToday
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    tooltip: 'Next Day',
                    onPressed: env.isSelectedDateToday ? null : () => env.goToNextDay(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Selectors (Temperature vs Humidity)
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
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _showTemperature = true);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Humidity (%)'),
                  selected: !_showTemperature,
                  selectedColor: const Color(0xFF38BDF8),
                  backgroundColor: theme.cardColor,
                  labelStyle: TextStyle(
                    color: !_showTemperature ? const Color(0xFF0F172A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _showTemperature = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Telemetry Highlights Strip
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Indoor Peak',
                    value: maxIn != null ? '${maxIn.toStringAsFixed(1)}$unit' : '--',
                    color: const Color(0xFF38BDF8),
                    icon: Icons.home_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Outdoor Peak',
                    value: maxOut != null ? '${maxOut.toStringAsFixed(1)}$unit' : '--',
                    color: const Color(0xFFFB923C),
                    icon: Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    title: 'Current Δ',
                    value: latestDelta != null
                        ? '${latestDelta >= 0 ? '+' : ''}${latestDelta.toStringAsFixed(1)}$unit'
                        : '--',
                    color: (latestDelta != null && latestDelta < 0)
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    icon: Icons.difference_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Chart Container Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showTemperature
                            ? 'Diurnal Temperature'
                            : 'Diurnal Humidity',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xFF38BDF8), 'Indoor (ESP32)', isDark),
                          const SizedBox(width: 10),
                          _buildLegendDot(const Color(0xFFFB923C), 'Outdoor', isDark),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '24-Hour continuous cycle for ${DateFormat('dd MMMM yyyy').format(selectedDate)}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chart Canvas
                  SizedBox(
                    height: 280,
                    child: points.isEmpty
                        ? Center(
                            child: Text(
                              'Collecting historical readings for this date...',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          )
                        : LineChart(_buildChartData(points, unit, isDark)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap and drag along the curve to inspect precise indoor vs outdoor values across any time of day.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                      ),
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

  // Realme-Style Calendar Modal matching user reference screenshot
  void _showRealmeCalendar(BuildContext context, EnvironmentProvider env) {
    DateTime displayedMonth = DateTime(env.selectedDate.year, env.selectedDate.month);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
            final firstWeekday = DateTime(displayedMonth.year, displayedMonth.month, 1).weekday % 7; // 0=Sun, 1=Mon...

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Realme Calendar Header (Cohesive Slate / Ocean Blue gradient matching app)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Month Navigation < YYYY-MM >
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                              onPressed: () {
                                setModalState(() {
                                  displayedMonth = DateTime(
                                    displayedMonth.year,
                                    displayedMonth.month - 1,
                                  );
                                });
                              },
                            ),
                            Text(
                              DateFormat('yyyy-MM').format(displayedMonth),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                              onPressed: (displayedMonth.year > now.year ||
                                      (displayedMonth.year == now.year && displayedMonth.month >= now.month))
                                  ? null
                                  : () {
                                      setModalState(() {
                                        displayedMonth = DateTime(
                                          displayedMonth.year,
                                          displayedMonth.month + 1,
                                        );
                                      });
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Weekday labels: Sun Mon Tue Wed Thu Fri Sat
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _WeekdayHeader('Sun'),
                            _WeekdayHeader('Mon'),
                            _WeekdayHeader('Tue'),
                            _WeekdayHeader('Wed'),
                            _WeekdayHeader('Thu'),
                            _WeekdayHeader('Fri'),
                            _WeekdayHeader('Sat'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Calendar Days Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < firstWeekday) {
                          return const SizedBox.shrink();
                        }
                        final dayNumber = index - firstWeekday + 1;
                        final cellDate = DateTime(displayedMonth.year, displayedMonth.month, dayNumber);
                        final cellDateStr = DateFormat('yyyy-MM-dd').format(cellDate);
                        final isSelected = cellDate.year == env.selectedDate.year &&
                            cellDate.month == env.selectedDate.month &&
                            cellDate.day == env.selectedDate.day;
                        final isFuture = cellDate.isAfter(today);
                        final isTodayCell = cellDate.isAtSameMomentAs(today);
                        final hasRecordedData = env.availableHistoryDates.contains(cellDateStr);

                        return InkWell(
                          onTap: isFuture
                              ? null
                              : () {
                                  env.setSelectedDate(cellDate);
                                  Navigator.pop(ctx);
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0EA5E9)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayNumber.toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected || isTodayCell ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (isFuture
                                            ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                                            : (isDark ? Colors.white : const Color(0xFF0F172A))),
                                  ),
                                ),
                                // Indicator dot ONLY for dates with verified recorded telemetry
                                if (hasRecordedData && !isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF38BDF8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                  // Realme-Style Bottom Split Actions: [ Cancel ] | [ Back to today ]
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: const Color(0xFF0EA5E9),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () {
                            env.resetToToday();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Back to today',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
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
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 11,
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
              fontSize: 15,
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 11,
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
      if (_showTemperature) {
        if (p.indoorTemperature != null) {
          indoorSpots.add(FlSpot(i.toDouble(), p.indoorTemperature!));
          minY = min(minY, p.indoorTemperature!);
          maxY = max(maxY, p.indoorTemperature!);
        }
        if (p.outdoorTemperature != null) {
          outdoorSpots.add(FlSpot(i.toDouble(), p.outdoorTemperature!));
          minY = min(minY, p.outdoorTemperature!);
          maxY = max(maxY, p.outdoorTemperature!);
        }
      } else {
        if (p.indoorHumidity != null) {
          indoorSpots.add(FlSpot(i.toDouble(), p.indoorHumidity!));
          minY = min(minY, p.indoorHumidity!);
          maxY = max(maxY, p.indoorHumidity!);
        }
        if (p.outdoorHumidity != null) {
          outdoorSpots.add(FlSpot(i.toDouble(), p.outdoorHumidity!));
          minY = min(minY, p.outdoorHumidity!);
          maxY = max(maxY, p.outdoorHumidity!);
        }
      }
    }

    if (minY == double.infinity) minY = 0;
    if (maxY == -double.infinity) maxY = 50;

    final padding = (maxY - minY) * 0.2;
    minY = (minY - padding).floorToDouble();
    maxY = (maxY + padding).ceilToDouble();
    if (minY < 0 && !_showTemperature) minY = 0;

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
            return touchedSpots.map((spot) {
              final idx = spot.spotIndex;
              final point = (idx >= 0 && idx < dynamicPoints.length) ? dynamicPoints[idx] : null;
              final timeStr = point != null ? DateFormat('HH:mm').format(point.timestamp) : '';
              final isIndoor = spot.barIndex == 0;
              final label = isIndoor ? 'Indoor' : 'Outdoor';

              return LineTooltipItem(
                '$timeStr\n$label: ${spot.y.toStringAsFixed(1)}$unit',
                TextStyle(
                  color: isIndoor ? const Color(0xFF38BDF8) : const Color(0xFFFB923C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: ((maxY - minY) / 5).clamp(2.0, 20.0),
        getDrawingHorizontalLine: (val) => FlLine(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          strokeWidth: 0.8,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: ((maxY - minY) / 4).clamp(2.0, 20.0),
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 10,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: max(1.0, (dynamicPoints.length / 5).floorToDouble()),
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < dynamicPoints.length) {
                final p = dynamicPoints[idx];
                return Text(
                  DateFormat('HH:mm').format(p.timestamp),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        // Indoor Trace (Neon Cyan)
        LineChartBarData(
          spots: indoorSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: const Color(0xFF38BDF8),
          barWidth: 3.2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF38BDF8).withValues(alpha: 0.25),
                const Color(0xFF38BDF8).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Outdoor Trace (Sunset Amber)
        LineChartBarData(
          spots: outdoorSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: const Color(0xFFFB923C),
          barWidth: 2.8,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFB923C).withValues(alpha: 0.18),
                const Color(0xFFFB923C).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
