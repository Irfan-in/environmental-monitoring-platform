import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';
import 'package:environmental_monitoring_platform/theme/wx_style.dart';
import 'package:environmental_monitoring_platform/widgets/comparison_bar.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final wx = Wx.of(context);

    final comp = env.comparisonData;
    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;

    return Scaffold(
      backgroundColor: wx.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Compare',
                  style: wx.t(24, w: FontWeight.w500),
                ),
              ),

              if (!env.isEsp32Online || indoor == null || outdoor == null) ...[
                // Offline Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: wx.bad.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: wx.bad.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        !env.isEsp32Online
                            ? Icons.sensors_off_rounded
                            : Icons.cloud_off_rounded,
                        color: wx.bad,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        !env.isEsp32Online
                            ? 'Sensor offline'
                            : 'Weather data unavailable',
                        style: TextStyle(
                          color: wx.bad,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !env.isEsp32Online
                            ? 'Comparison analysis will resume once the indoor sensor reconnects.'
                            : 'Waiting for weather sync.',
                        textAlign: TextAlign.center,
                        style: wx.t(12, c: wx.bad),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                if (outdoor != null) ...[
                  Text(
                    'Outdoor conditions',
                    style: wx.t(13, w: FontWeight.w600, c: wx.accent),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: wx.card,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              outdoor.city,
                              style: wx.t(16, w: FontWeight.w600),
                            ),
                            Text(
                              outdoor.weatherDesc,
                              style: TextStyle(
                                color: wx.outdoorLine,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Outdoor Temp',
                                    style: wx.t(11, c: wx.textDim)),
                                const SizedBox(height: 4),
                                Text(
                                  '${outdoor.temperature.toStringAsFixed(1)}°C',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: wx.outdoorLine,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: wx.textDim.withValues(alpha: 0.2),
                            ),
                            Column(
                              children: [
                                Text('Outdoor Humidity',
                                    style: wx.t(11, c: wx.textDim)),
                                const SizedBox(height: 4),
                                Text(
                                  '${outdoor.humidity.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: wx.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Temperature Comparison Bar
                ComparisonBar(
                  label: 'Temperature',
                  indoorVal: indoor.temperature,
                  outdoorVal: outdoor.temperature,
                  unit: '°C',
                  indoorColor: wx.accent,
                  outdoorColor: wx.outdoorLine,
                ),
                const SizedBox(height: 14),

                // Humidity Comparison Bar
                ComparisonBar(
                  label: 'Humidity',
                  indoorVal: indoor.humidity,
                  outdoorVal: outdoor.humidity,
                  unit: '%',
                  indoorColor: wx.accent,
                  outdoorColor: wx.outdoorLine,
                ),
                const SizedBox(height: 18),

                // Heat Index (Feels Like Index)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: wx.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feels like index',
                        style: wx.t(15, w: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: wx.bg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Indoor',
                                    style: wx.t(12, c: wx.textDim),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comp?.indoorHeatIndex != null
                                        ? '${comp!.indoorHeatIndex!.toStringAsFixed(1)}°C'
                                        : '${(indoor.temperature + 0.5).toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      color: wx.accent,
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: wx.bg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Outdoor',
                                    style: wx.t(12, c: wx.textDim),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comp?.outdoorHeatIndex != null
                                        ? '${comp!.outdoorHeatIndex!.toStringAsFixed(1)}°C'
                                        : '${(outdoor.temperature + 1.2).toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      color: wx.outdoorLine,
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
                const SizedBox(height: 18),

                // Environmental Advice Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: wx.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: wx.warn, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Insights',
                            style: wx.t(15, w: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInsightRow(
                        wx: wx,
                        icon: Icons.air,
                        title: 'Ventilation',
                        text: outdoor.temperature < indoor.temperature
                            ? 'Outside air is cooler than indoors. Opening windows provides natural cooling.'
                            : 'Outside temperature is warmer than indoors. Keep windows closed to retain cool air.',
                      ),
                      Divider(
                        color: wx.textDim.withValues(alpha: 0.15),
                        height: 22,
                      ),
                      _buildInsightRow(
                        wx: wx,
                        icon: Icons.water_drop_outlined,
                        title: 'Humidity',
                        text: indoor.humidity > 65
                            ? 'Indoor humidity is high (>65%). Ventilation or dehumidification recommended.'
                            : indoor.humidity < 35
                                ? 'Indoor air is dry (<35%). A humidifier could improve comfort.'
                                : 'Indoor humidity is in the optimal comfort range.',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow({
    required Wx wx,
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: wx.textDim, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: wx.t(13, w: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: wx.t(12, c: wx.textDim),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
