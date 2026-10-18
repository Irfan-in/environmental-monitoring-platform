import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/comparison_bar.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final comp = env.comparisonData;
    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Text(
          'Indoor vs Outdoor Comparison',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: (indoor == null || outdoor == null)
          ? Center(
              child: Text(
                'Waiting for both indoor and outdoor data to compare...',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Temperature Differential Bar
                  ComparisonBar(
                    label: 'Temperature Comparison',
                    indoorVal: indoor.temperature,
                    outdoorVal: outdoor.temperature,
                    unit: '°C',
                  ),
                  const SizedBox(height: 16),

                  // Humidity Differential Bar
                  ComparisonBar(
                    label: 'Humidity Comparison',
                    indoorVal: indoor.humidity,
                    outdoorVal: outdoor.humidity,
                    unit: '%',
                  ),
                  const SizedBox(height: 20),

                  // Heat Index (Apparent Feeling)
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
                          color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apparent Heat Index (Real Feel)',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Indoor Index',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comp?.indoorHeatIndex != null
                                          ? '${comp!.indoorHeatIndex!.toStringAsFixed(1)}°C'
                                          : '${(indoor.temperature + 0.5).toStringAsFixed(1)}°C',
                                      style: const TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Outdoor Index',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comp?.outdoorHeatIndex != null
                                          ? '${comp!.outdoorHeatIndex!.toStringAsFixed(1)}°C'
                                          : '${(outdoor.temperature + 1.2).toStringAsFixed(1)}°C',
                                      style: const TextStyle(
                                        color: Color(0xFFFB923C),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Practical Recommendations Card
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
                          color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Smart Environmental Insights',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInsightRow(
                          isDark: isDark,
                          icon: Icons.air,
                          title: 'Ventilation Advice',
                          text: outdoor.temperature < indoor.temperature
                              ? 'Outside air is cooler than indoors. Opening windows can provide natural cooling and save energy.'
                              : 'Outdoor temperature is warmer than indoors. Keep windows closed to retain indoor conditioned air.',
                        ),
                        Divider(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          height: 20,
                        ),
                        _buildInsightRow(
                          isDark: isDark,
                          icon: Icons.water_drop_outlined,
                          title: 'Humidity Management',
                          text: indoor.humidity > 65
                              ? 'Indoor humidity is elevated (>65%). Dehumidification or increased ventilation is suggested.'
                              : indoor.humidity < 35
                                  ? 'Indoor air is dry (<35%). Consider using a humidifier to improve comfort.'
                                  : 'Indoor humidity is within optimal healthy range (40%-60%).',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
