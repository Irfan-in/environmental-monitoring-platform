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
      body: (!env.isEsp32Online || indoor == null || outdoor == null)
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          !env.isEsp32Online ? Icons.sensors_off_rounded : Icons.cloud_off_rounded,
                          color: const Color(0xFFEF4444),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !env.isEsp32Online ? 'ESP32 Node Offline' : 'Weather Data Unavailable',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !env.isEsp32Online
                              ? 'Indoor vs outdoor differential analysis is paused until the ESP32 reconnects via Bluetooth or Wi-Fi.'
                              : 'Outdoor weather data is currently unavailable. Waiting for sync.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'CURRENT OUTDOOR CONDITIONS',
                    style: TextStyle(
                      color: Color(0xFFFB923C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (outdoor != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                outdoor.city,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                outdoor.weatherDesc,
                                style: const TextStyle(color: Color(0xFFFB923C), fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Outdoor Temp', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${outdoor.temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFB923C)),
                                  ),
                                ],
                              ),
                              Container(height: 30, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              Column(
                                children: [
                                  const Text('Outdoor Humidity', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${outdoor.humidity.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                          color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
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
