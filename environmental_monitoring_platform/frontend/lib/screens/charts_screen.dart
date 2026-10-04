import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Historical Trends',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Pills
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
                        _showTemperature ? 'Temperature History' : 'Humidity History',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xFF38BDF8), 'Indoor'),
                          const SizedBox(width: 12),
                          _buildLegendDot(const Color(0xFFFB923C), 'Outdoor'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chart Canvas
                  SizedBox(
                    height: 260,
                    child: points.isEmpty
                        ? const Center(
                            child: Text(
                              'Collecting historical readings...',
                              style: TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          )
                        : LineChart(_buildChartData(points)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                  const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chart displays up to 30 recent synchronized samples from SQLite storage.',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List dynamicPoints) {
    final List<FlSpot> indoorSpots = [];
    final List<FlSpot> outdoorSpots = [];

    for (int i = 0; i < dynamicPoints.length; i++) {
      final p = dynamicPoints[i];
      if (_showTemperature) {
        if (p.indoorTemperature != null) {
          indoorSpots.add(FlSpot(i.toDouble(), p.indoorTemperature!));
        }
        if (p.outdoorTemperature != null) {
          outdoorSpots.add(FlSpot(i.toDouble(), p.outdoorTemperature!));
        }
      } else {
        if (p.indoorHumidity != null) {
          indoorSpots.add(FlSpot(i.toDouble(), p.indoorHumidity!));
        }
        if (p.outdoorHumidity != null) {
          outdoorSpots.add(FlSpot(i.toDouble(), p.outdoorHumidity!));
        }
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 5,
        getDrawingHorizontalLine: (val) => FlLine(
          color: const Color(0xFF334155),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 5,
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
        // Indoor Line
        LineChartBarData(
          spots: indoorSpots,
          isCurved: true,
          color: const Color(0xFF38BDF8),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF38BDF8).withOpacity(0.1),
          ),
        ),
        // Outdoor Line
        LineChartBarData(
          spots: outdoorSpots,
          isCurved: true,
          color: const Color(0xFFFB923C),
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}
