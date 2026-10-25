import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/models/chart_point.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF16192C),
              Color(0xFF211D3A),
              Color(0xFF282240),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE7E2F8),
              Color(0xFFEDE8FA),
              Color(0xFFF5F3FC),
            ],
          );

    final cardBg = isDark
        ? const Color(0xFF262442).withValues(alpha: 0.92)
        : const Color(0xFFE1DAFA).withValues(alpha: 0.65);
    final whiteCardBg =
        isDark ? const Color(0xFF2B294B) : Colors.white.withValues(alpha: 0.92);
    final primaryText = isDark ? Colors.white : const Color(0xFF1B1C22);
    final secondaryText =
        isDark ? const Color(0xFFB3B6CE) : const Color(0xFF5A5D72);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header ("10-day forecast" & Lavender Redesign style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights_rounded,
                            color: Color(0xFF7C4DFF), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Comparative forecast & telemetry',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.calendar_month_rounded,
                              color: primaryText, size: 21),
                          onPressed: () => _showCalendar(context, env),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded,
                              color: primaryText, size: 21),
                          onPressed: () => env.fetchHistoryForSelectedDate(),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. Vertical Capsule Strip (Pixel Weather Right Screen 10-day capsules)
                _buildDateCapsuleStrip(
                  env: env,
                  selectedDate: selectedDate,
                  whiteCardBg: whiteCardBg,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // 3. Large Dual Hero Summary ("August 9 / San Francisco / 66°/55°" style)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMMM d, yyyy').format(selectedDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            env.outdoorReading?.city ?? 'ESP32-ENV-01 Station',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${latestIn != null ? latestIn.toStringAsFixed(1) : "--"}$unit/${latestOut != null ? latestOut.toStringAsFixed(1) : "--"}$unit',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            latestDelta != null
                                ? 'Indoor vs Outdoor • Delta ${latestDelta >= 0 ? "+" : ""}${latestDelta.toStringAsFixed(1)}$unit'
                                : 'Real-time Synchronized Dual Trace',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: whiteCardBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showTemperature
                            ? Icons.wb_sunny_rounded
                            : Icons.water_drop_rounded,
                        size: 40,
                        color: _showTemperature
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF7C4DFF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Lavender Segmented Pill Tabs ("Today | Tomorrow | 10 days" style)
                Row(
                  children: [
                    _buildPillChip(
                      label: 'Temperature (°C)',
                      selected: _showTemperature,
                      isDark: isDark,
                      onTap: () => setState(() => _showTemperature = true),
                    ),
                    const SizedBox(width: 8),
                    _buildPillChip(
                      label: 'Humidity (%)',
                      selected: !_showTemperature,
                      isDark: isDark,
                      onTap: () => setState(() => _showTemperature = false),
                    ),
                    const Spacer(),
                    _buildPillChip(
                      label: _liveWindowOnly ? '30m Live' : 'Full Day',
                      selected: _liveWindowOnly,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _liveWindowOnly = !_liveWindowOnly),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 5. Smooth Spline Curve Card ("Day forecast" Lavender Card)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
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
                                  size: 18, color: primaryText),
                              const SizedBox(width: 6),
                              Text(
                                _showTemperature
                                    ? 'Day temperature curve'
                                    : 'Day humidity curve',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: primaryText,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildLegendDot(
                                  const Color(0xFF6E44FF), 'Indoor', isDark),
                              const SizedBox(width: 10),
                              _buildLegendDot(
                                  const Color(0xFFFB923C), 'Outdoor', isDark),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 230,
                        child: displayPoints.isEmpty
                            ? Center(
                                child: Text(
                                  'Archiving telemetry records locally...',
                                  style: TextStyle(
                                      color: secondaryText, fontSize: 12),
                                ),
                              )
                            : LineChart(_buildChartData(
                                displayPoints, unit, isDark, primaryText)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Horizontal Progress Bars Card ("Chance of rain" Purple Bars style)
                _buildHorizontalBarsCard(
                  points: displayPoints,
                  unit: unit,
                  cardBg: cardBg,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCapsuleStrip({
    required EnvironmentProvider env,
    required DateTime selectedDate,
    required Color whiteCardBg,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    final days = List.generate(
      6,
      (i) => DateTime.now().subtract(Duration(days: 5 - i)),
    );

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, idx) {
          final d = days[idx];
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;

          final pillColor =
              isSelected ? const Color(0xFF335594) : whiteCardBg;
          final txtColor = isSelected ? Colors.white : primaryText;

          return GestureDetector(
            onTap: () => env.setSelectedDate(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: txtColor,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(d),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : secondaryText,
                    ),
                  ),
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFFFFCF4B)
                        : const Color(0xFFF59E0B),
                  ),
                  Text(
                    DateFormat('E').format(d),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
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
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF7C4DFF) : const Color(0xFFD6C4FF))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF281856))
                : (isDark ? Colors.white70 : const Color(0xFF1B1C22)),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBarsCard({
    required List<ChartPoint> points,
    required String unit,
    required Color cardBg,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    final slice = points.length > 4
        ? points.sublist(points.length - 4).reversed.toList()
        : points.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.align_horizontal_left_rounded,
                  size: 16, color: primaryText),
              const SizedBox(width: 8),
              Text(
                _showTemperature
                    ? 'Recent thermal intensity'
                    : 'Recent humidity saturation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (slice.isEmpty)
            Text(
              'Awaiting sensor samples...',
              style: TextStyle(fontSize: 12, color: secondaryText),
            )
          else
            ...slice.map((p) {
              final val = (_showTemperature
                      ? p.indoorTemperature
                      : p.indoorHumidity) ??
                  0.0;
              final ratio = _showTemperature
                  ? (val / 45.0).clamp(0.15, 1.0)
                  : (val / 100.0).clamp(0.15, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        DateFormat('HH:mm').format(p.timestamp.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 16,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.75),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7B2CBF)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${val.toStringAsFixed(1)}$unit',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
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
            color: isDark ? const Color(0xFFB3B6CE) : const Color(0xFF5A5D72),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(
    List<ChartPoint> dynamicPoints,
    String unit,
    bool isDark,
    Color primaryText,
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
          getTooltipColor: (_) =>
              isDark ? const Color(0xFF1E1B36) : Colors.white,
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isIndoor = spot.barIndex == 0;
              return LineTooltipItem(
                '${isIndoor ? "Indoor" : "Outdoor"}: ${spot.y.toStringAsFixed(1)}$unit',
                TextStyle(
                  color: isIndoor
                      ? const Color(0xFF7C4DFF)
                      : const Color(0xFFFB923C),
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFC5B9E8).withValues(alpha: 0.5),
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
              style: TextStyle(
                color: primaryText.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
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
                    style: TextStyle(
                      color: primaryText.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
          color: const Color(0xFF4F378B),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C4DFF).withValues(alpha: 0.32),
                const Color(0xFF7C4DFF).withValues(alpha: 0.02),
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
          color: const Color(0xFFFB923C),
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
