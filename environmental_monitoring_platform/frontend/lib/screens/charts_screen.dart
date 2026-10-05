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
    final points = env.historyPoints;

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Diurnal Comparison Chart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selectors
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Temperature (°C)'),
                  selected: _showTemperature,
                  selectedColor: const Color(0xFF38BDF8),
                  labelStyle: TextStyle(
                    color: _showTemperature ? const Color(0xFF0F172A) : Colors.white,
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
                  labelStyle: TextStyle(
                    color: !_showTemperature ? const Color(0xFF0F172A) : Colors.white,
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
                    title: 'Indoor Peak',
                    value: maxIn != null ? '${maxIn.toStringAsFixed(1)}$unit' : '--',
                    color: const Color(0xFF38BDF8),
                    icon: Icons.home_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: 'Outdoor Peak',
                    value: maxOut != null ? '${maxOut.toStringAsFixed(1)}$unit' : '--',
                    color: const Color(0xFFFB923C),
                    icon: Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
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
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showTemperature
                            ? 'Dual-Series Diurnal Temperature'
                            : 'Dual-Series Diurnal Humidity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xFF38BDF8), 'Indoor (ESP32)'),
                          const SizedBox(width: 10),
                          _buildLegendDot(const Color(0xFFFB923C), 'Outdoor'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Smooth cubic Bezier comparison curve across diurnal cycle',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // Chart Canvas
                  SizedBox(
                    height: 280,
                    child: points.isEmpty
                        ? const Center(
                            child: Text(
                              'Collecting historical readings...',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          )
                        : LineChart(_buildChartData(points, unit)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tap and drag along the curve to inspect precise indoor vs outdoor differential (Δ) at each hour of the day.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
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
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
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

  Widget _buildLegendDot(Color color, String label) {
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
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<ChartPoint> dynamicPoints, String unit) {
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
          getTooltipColor: (_) => const Color(0xFF0F172A),
          tooltipBorder: const BorderSide(color: Color(0xFF334155)),
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
        getDrawingHorizontalLine: (val) => const FlLine(
          color: Color(0xFF334155),
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
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
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
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
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
                const Color(0xFF38BDF8).withOpacity(0.25),
                const Color(0xFF38BDF8).withOpacity(0.0),
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
                const Color(0xFFFB923C).withOpacity(0.18),
                const Color(0xFFFB923C).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
