import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();

    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;
    final comparison = env.comparisonData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Environmental Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: env.isSyncingWeather
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_sync_outlined),
            tooltip: 'Sync Outdoor Weather',
            onPressed: () => env.syncWeather(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => env.fetchData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => env.fetchData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Alerts Banner if alerts exist
              if (env.unacknowledgedAlertCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${env.unacknowledgedAlertCount} environmental alert(s) require attention!',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Section Header: Indoor Environment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INDOOR ENVIRONMENT',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                        const SizedBox(width: 4),
                        Text(
                          indoor != null ? indoor.deviceId : 'ESP32 Offline',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Indoor Metric Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Temperature',
                      value: indoor != null ? indoor.temperature.toStringAsFixed(1) : '--',
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: const Color(0xFFF87171),
                      subtitle: indoor != null
                          ? 'Updated ${DateFormat('HH:mm:ss').format(indoor.timestamp)}'
                          : 'Awaiting sensor...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Humidity',
                      value: indoor != null ? indoor.humidity.toStringAsFixed(1) : '--',
                      unit: '%',
                      icon: Icons.water_drop,
                      accentColor: const Color(0xFF38BDF8),
                      subtitle: 'Relative Humidity',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Header: Outdoor Weather
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OUTDOOR ENVIRONMENT',
                    style: TextStyle(
                      color: Color(0xFFFB923C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    outdoor != null ? outdoor.city : 'Weather API',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Outdoor Metric Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Outdoor Temp',
                      value: outdoor != null ? outdoor.temperature.toStringAsFixed(1) : '--',
                      unit: '°C',
                      icon: Icons.wb_sunny_outlined,
                      accentColor: const Color(0xFFFB923C),
                      subtitle: outdoor != null ? outdoor.weatherDesc : 'Open-Meteo',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Outdoor Humidity',
                      value: outdoor != null ? outdoor.humidity.toStringAsFixed(1) : '--',
                      unit: '%',
                      icon: Icons.cloud_outlined,
                      accentColor: const Color(0xFF38BDF8),
                      subtitle: outdoor != null ? 'Wind: ${outdoor.windSpeed} km/h' : '--',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Thermal Comfort Overview Card
              if (comparison != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF162033)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.shield_moon_outlined, color: Color(0xFF38BDF8), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Thermal Comfort Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        comparison.comfortAssessment,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comparison.statusSummary,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
