import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = Indoor ESP32 Focus, 1 = Outdoor Reference Focus, 2 = Combined Overview
  int _selectedTab = 0;

  // Compute approximate Feels Like / Heat Index in °C
  double _computeFeelsLike(double tempC, double humidity) {
    final tempF = tempC * 9 / 5 + 32;
    if (tempF < 80) {
      return tempC + (humidity - 50) * 0.03;
    }
    final hiF = -42.379 +
        2.04901523 * tempF +
        10.14333127 * humidity -
        0.22475541 * tempF * humidity -
        0.00683783 * tempF * tempF -
        0.05481717 * humidity * humidity +
        0.00122874 * tempF * tempF * humidity +
        0.00085282 * tempF * humidity * humidity -
        0.00000199 * tempF * tempF * humidity * humidity;
    return (hiF - 32) * 5 / 9;
  }

  // Compute Magnus Dew Point in °C
  double _computeDewPoint(double tempC, double humidity) {
    final rh = humidity.clamp(1.0, 100.0);
    const a = 17.27;
    const b = 237.7;
    final alpha = ((a * tempC) / (b + tempC)) + math.log(rh / 100.0);
    return (b * alpha) / (a - alpha);
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<EnvironmentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;
    final comparison = env.comparisonData;
    final isEsp32Online = env.isEsp32Online;

    final primaryTemp = _selectedTab == 1
        ? outdoor?.temperature
        : (isEsp32Online ? indoor?.temperature : outdoor?.temperature);
    final primaryHum = _selectedTab == 1
        ? outdoor?.humidity
        : (isEsp32Online ? indoor?.humidity : outdoor?.humidity);

    final feelsLike = (primaryTemp != null && primaryHum != null)
        ? _computeFeelsLike(primaryTemp, primaryHum)
        : null;
    final dewPoint = (primaryTemp != null && primaryHum != null)
        ? _computeDewPoint(primaryTemp, primaryHum)
        : null;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF15192B),
              Color(0xFF1F1D38),
              Color(0xFF2A233E),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFCBD9F0),
              Color(0xFFE5DFEE),
              Color(0xFFF2DEC2),
            ],
          );

    final cardBg = isDark
        ? const Color(0xFF252641).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.88);
    final primaryText = isDark ? Colors.white : const Color(0xFF1B1C22);
    final secondaryText =
        isDark ? const Color(0xFFB3B6CE) : const Color(0xFF545868);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => env.fetchData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Pixel Weather Top Location & Action Bar
                  _buildTopBar(
                    context: context,
                    env: env,
                    isDark: isDark,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                  ),

                  // 2. Active Climate Advisory Pill (if any)
                  if (env.activeClimateAdvisory != null) ...[
                    const SizedBox(height: 10),
                    _buildAdvisoryBanner(env, isDark),
                  ],

                  const SizedBox(height: 18),

                  // 3. Center Hero Weather Display (Pixel Weather "70°" Style)
                  Text(
                    _selectedTab == 1
                        ? (outdoor?.weatherDesc ?? 'Partly Cloudy')
                        : (comparison?.comfortAssessment ??
                            (isEsp32Online
                                ? 'Optimal Microclimate'
                                : 'Standby • Using Ambient Cache')),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        primaryTemp != null
                            ? '${primaryTemp.toStringAsFixed(1)}°'
                            : '--°',
                        style: TextStyle(
                          fontSize: 76,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: -3,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 68,
                        height: 68,
                        child: CustomPaint(
                          painter: _ScallopedSunCloudPainter(showCloud: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feelsLike != null
                        ? 'Feels like ${feelsLike.toStringAsFixed(1)}°'
                        : 'Feels like --°',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryText.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Indoor ${isEsp32Online && indoor != null ? "${indoor.temperature.toStringAsFixed(1)}°" : "--°"} · Outdoor ${outdoor != null ? "${outdoor.temperature.toStringAsFixed(1)}°" : "--°"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Lavender Segmented Pill Tabs ("Today | Tomorrow | 10 days" style)
                  _buildModePillTabs(isDark, primaryText),

                  const SizedBox(height: 18),

                  // 5. Hourly Telemetry Strip Card (Pixel Weather Hourly Card)
                  _buildHourlyTelemetryCard(
                    env: env,
                    cardBg: cardBg,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  // 6. Vertical Capsule Snapshot Card ("10-day forecast" Capsule Style)
                  _buildCapsuleComparisonCard(
                    env: env,
                    cardBg: cardBg,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  // 7. Expressive Material You 2x3 Bento Grid
                  // Row 1: Circular Wind Card + Horizon Comfort Arc Card
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildCircularWindCard(
                            outdoor: outdoor,
                            isDark: isDark,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildHorizonSyncCard(
                            env: env,
                            isDark: isDark,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 2: Scalloped Starburst Delta Card + Spectrum Comfort Index Card
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildScallopedDeltaCard(
                            tempDiff: comparison?.tempDiff,
                            isDark: isDark,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildComfortSpectrumCard(
                            indoorTemp: indoor?.temperature,
                            assessment:
                                comparison?.comfortAssessment ?? 'Optimal',
                            cardBg: cardBg,
                            isDark: isDark,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 3: Circular Gauge Storage Card + Liquid Wave Humidity Card
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildCircularGaugeCard(
                            env: env,
                            isDark: isDark,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: _buildWavyHumidityCard(
                            humidity: primaryHum,
                            dewPoint: dewPoint,
                            isDark: isDark,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 8. RBAC User Status & Local Storage Pill
                  _buildFooterSessionBar(
                    context: context,
                    env: env,
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
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required EnvironmentProvider env,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final city = env.outdoorReading?.city ?? 'Environmental Station';
    final isOnline = env.isEsp32Online;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'ESP32 Live' : 'Standby',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                city,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM d • HH:mm').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            env.isLoggedIn
                ? Icons.account_circle
                : Icons.account_circle_outlined,
            color: primaryText,
          ),
          tooltip: 'User Account',
          onPressed: () => _showUserLoginSheet(context, env),
        ),
        IconButton(
          icon: Icon(Icons.tune_rounded, color: primaryText),
          tooltip: 'Station Settings',
          onPressed: () => _showSettingsSheet(context, env),
        ),
      ],
    );
  }

  Widget _buildAdvisoryBanner(EnvironmentProvider env, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A2A23) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              env.activeClimateAdvisory!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(
            onPressed: () => env.dismissAdvisory(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Dismiss',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePillTabs(bool isDark, Color primaryText) {
    final labels = ['Indoor Node', 'Ambient Ref', 'Dual Compare'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (index) {
        final selected = _selectedTab == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                        ? const Color(0xFF8B72FF)
                        : const Color(0xFFD7C6FF))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.75)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? (isDark ? Colors.white : const Color(0xFF281B52))
                      : primaryText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHourlyTelemetryCard({
    required EnvironmentProvider env,
    required Color cardBg,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    final points = env.historyPoints;
    final recentPoints = points.length > 8
        ? points.sublist(points.length - 8).reversed.toList()
        : points.reversed.toList();

    return Container(
      width: double.infinity,
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
              Icon(Icons.access_time_rounded, size: 18, color: secondaryText),
              const SizedBox(width: 8),
              Text(
                'Hourly telemetry stream',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: recentPoints.isEmpty
                ? Center(
                    child: Text(
                      'Collecting live ESP32 & satellite telemetry...',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentPoints.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, idx) {
                      final p = recentPoints[idx];
                      final isFirst = idx == 0;
                      final temp = _selectedTab == 1
                          ? (p.outdoorTemperature ??
                              p.indoorTemperature ??
                              0.0)
                          : (p.indoorTemperature ??
                              p.outdoorTemperature ??
                              0.0);
                      final hum = _selectedTab == 1
                          ? p.outdoorHumidity
                          : p.indoorHumidity;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? const Color(0xFF335594)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${temp.toStringAsFixed(0)}°',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isFirst ? Colors.white : primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 26,
                            height: 26,
                            child: CustomPaint(
                              painter:
                                  _ScallopedSunCloudPainter(showCloud: true),
                            ),
                          ),
                          if (hum != null)
                            Text(
                              '${hum.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A78D0),
                              ),
                            ),
                          Text(
                            isFirst
                                ? 'Now'
                                : DateFormat('HH:mm')
                                    .format(p.timestamp.toLocal()),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isFirst ? FontWeight.w700 : FontWeight.w500,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleComparisonCard({
    required EnvironmentProvider env,
    required Color cardBg,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    final indoor = env.indoorReading;
    final outdoor = env.outdoorReading;
    final diff = env.comparisonData?.tempDiff;

    final capsules = [
      (
        label: 'Now',
        high:
            indoor != null ? '${indoor.temperature.toStringAsFixed(0)}°' : '--°',
        low: outdoor != null
            ? '${outdoor.temperature.toStringAsFixed(0)}°'
            : '--°',
        sub: indoor != null ? '${indoor.humidity.toStringAsFixed(0)}%' : '--%',
        active: true,
      ),
      (
        label: 'Indoor',
        high:
            indoor != null ? '${indoor.temperature.toStringAsFixed(1)}°' : '--°',
        low: 'DHT22',
        sub: indoor != null ? '${indoor.humidity.toStringAsFixed(0)}%' : '--%',
        active: false,
      ),
      (
        label: 'Outdoor',
        high: outdoor != null
            ? '${outdoor.temperature.toStringAsFixed(1)}°'
            : '--°',
        low: 'Meteo',
        sub:
            outdoor != null ? '${outdoor.humidity.toStringAsFixed(0)}%' : '--%',
        active: false,
      ),
      (
        label: 'Delta',
        high: diff != null
            ? '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)}°'
            : '--°',
        low: 'ΔT',
        sub: 'ASHRAE',
        active: false,
      ),
      (
        label: 'Offset',
        high:
            '${env.temperatureOffset >= 0 ? "+" : ""}${env.temperatureOffset.toStringAsFixed(1)}°',
        low: 'Calib',
        sub: 'GPIO4',
        active: false,
      ),
    ];

    return Container(
      width: double.infinity,
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
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: secondaryText),
              const SizedBox(width: 8),
              Text(
                'Microclimate capsule overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: capsules.map((c) {
              final pillColor = c.active
                  ? const Color(0xFF335594)
                  : (isDark
                      ? const Color(0xFF313352)
                      : const Color(0xFFF5F4FA));
              final textCol = c.active ? Colors.white : primaryText;
              final subCol = c.active ? Colors.white70 : secondaryText;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    children: [
                      Text(
                        c.high,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.low,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: subCol,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CustomPaint(
                          painter: _ScallopedSunCloudPainter(showCloud: true),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.sub,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c.active
                              ? const Color(0xFFBAE6FD)
                              : const Color(0xFF4A78D0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textCol,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularWindCard({
    required dynamic outdoor,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final wind = outdoor?.windSpeed ?? 4.2;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF282B4A) : const Color(0xFFF3F4FC),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.air_rounded, size: 16, color: secondaryText),
              const SizedBox(width: 4),
              Text(
                'Wind',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: wind.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                TextSpan(
                  text: ' km/h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            outdoor?.weatherDesc ?? 'Ambient Sync',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizonSyncCard({
    required EnvironmentProvider env,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final lastTime = env.indoorReading != null
        ? DateFormat('HH:mm:ss').format(env.indoorReading!.timestamp.toLocal())
        : 'Standby';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: isDark ? const Color(0xFF282B4A) : const Color(0xFFF5F6FC),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HorizonArcPainter(isDark: isDark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sensors_rounded,
                          size: 16, color: secondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Telemetry cycle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Last Packet: $lastTime',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Poll: 4s • Cloud Sync: 15m',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: secondaryText,
                          ),
                        ),
                      ],
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

  Widget _buildScallopedDeltaCard({
    required double? tempDiff,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final formatted = tempDiff != null
        ? '${tempDiff >= 0 ? "+" : ""}${tempDiff.toStringAsFixed(1)}°'
        : '--°';
    final status = tempDiff == null
        ? 'Syncing'
        : (tempDiff.abs() < 2.0
            ? 'Balanced'
            : (tempDiff > 0 ? 'Warmer Inside' : 'Cooler Inside'));

    return CustomPaint(
      painter: _ScallopedBadgePainter(
        color: isDark ? const Color(0xFF2B2848) : const Color(0xFFF6F6FC),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compare_arrows_rounded,
                    size: 15, color: secondaryText),
                const SizedBox(width: 4),
                Text(
                  'Delta (ΔT)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatted,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (tempDiff != null && tempDiff > 2)
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComfortSpectrumCard({
    required double? indoorTemp,
    required String assessment,
    required Color cardBg,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final norm = indoorTemp != null
        ? ((indoorTemp - 16.0) / 18.0).clamp(0.05, 0.95)
        : 0.45;
    final score = indoorTemp != null
        ? (100 - ((indoorTemp - 24.0).abs() * 6)).clamp(40, 99).toInt()
        : 92;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.waves_rounded, size: 16, color: secondaryText),
              const SizedBox(width: 6),
              Text(
                'ASHRAE 55',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF22C55E),
                          Color(0xFFEAB308),
                          Color(0xFFF97316),
                          Color(0xFFEF4444),
                          Color(0xFF9333EA),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth - 12) * norm,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Text(
            assessment,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularGaugeCard({
    required EnvironmentProvider env,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return CustomPaint(
      painter: _CircularGaugePainter(
        isDark: isDark,
        progress: env.isEsp32Online ? 0.78 : 0.35,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.memory_rounded, size: 14, color: secondaryText),
                const SizedBox(width: 4),
                Text(
                  'Records',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${env.localRecordCount}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cached pts',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWavyHumidityCard({
    required double? humidity,
    required double? dewPoint,
    required bool isDark,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final fillRatio = ((humidity ?? 60.0) / 100.0).clamp(0.15, 0.88);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: isDark ? const Color(0xFF282542) : Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WavyLiquidPainter(
                  fillRatio: fillRatio,
                  waveColor: isDark
                      ? const Color(0xFF4B3266)
                      : const Color(0xFFF6D9FA),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop_rounded,
                          size: 15, color: primaryText),
                      const SizedBox(width: 6),
                      Text(
                        'Humidity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    humidity != null
                        ? '${humidity.toStringAsFixed(0)}%'
                        : '--%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF6B4C8C)
                              : const Color(0xFF6E5278),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          dewPoint != null
                              ? '${dewPoint.toStringAsFixed(0)}°'
                              : '--°',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dew point',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSessionBar({
    required BuildContext context,
    required EnvironmentProvider env,
    required Color cardBg,
    required Color primaryText,
    required Color secondaryText,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            env.isLoggedIn ? Icons.verified_user_rounded : Icons.person_outline,
            size: 18,
            color:
                env.isLoggedIn ? const Color(0xFF10B981) : secondaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              env.isLoggedIn
                  ? 'Operator: ${env.username} • ${env.connectionMode}'
                  : 'Guest Mode • ${env.connectionMode}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showUserLoginSheet(context, env),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              env.isLoggedIn ? 'Switch' : 'Log In',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF335594),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessDeniedDialog(BuildContext context, EnvironmentProvider env) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2238) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: Color(0xFFF59E0B), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please sign in to your account to adjust sensor calibration or change station settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF335594),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Log In',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showUserLoginSheet(context, env);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context, EnvironmentProvider env) {
    if (!env.isLoggedIn) {
      _showAccessDeniedDialog(context, env);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serverController = TextEditingController(text: ApiService.baseUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2238) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Station Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Mode Appearance',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      value: env.isDarkMode,
                      onChanged: (_) {
                        env.toggleTheme();
                        setSheetState(() {});
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Temperature Calibration Offset',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          '${env.temperatureOffset >= 0 ? "+" : ""}${env.temperatureOffset.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF335594)),
                        ),
                      ],
                    ),
                    Slider(
                      value: env.temperatureOffset,
                      min: -5.0,
                      max: 5.0,
                      divisions: 20,
                      onChanged: (val) {
                        env.setTemperatureOffset(val);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: serverController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Cloud Gateway URL',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, size: 18),
                          onPressed: () {
                            ApiService.setBaseUrl(serverController.text.trim());
                            env.fetchData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Gateway endpoint saved!')),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_sweep_outlined,
                                size: 16),
                            label: const Text('Clear Storage'),
                            onPressed: () async {
                              await env.clearLocalStorage();
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Force Sync'),
                            onPressed: () async {
                              await env.fetchData();
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserLoginSheet(BuildContext context, EnvironmentProvider env) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userController = TextEditingController(text: 'irfan');
    final passController = TextEditingController(text: '1234');
    String? authError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2238) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    env.isLoggedIn
                        ? 'Account: ${env.username}'
                        : 'Operator Sign In',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (env.isLoggedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon:
                            const Icon(Icons.logout, color: Color(0xFFEF4444)),
                        label: const Text('Log Out',
                            style: TextStyle(color: Color(0xFFEF4444))),
                        onPressed: () async {
                          await env.logout();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ] else ...[
                    if (authError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(authError!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 12)),
                      ),
                    TextField(
                      controller: userController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF335594),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final err = await env.login(
                            userController.text.trim(),
                            passController.text.trim(),
                          );
                          if (err != null) {
                            setSheetState(() => authError = err);
                          } else if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ScallopedSunCloudPainter extends CustomPainter {
  final bool showCloud;
  const _ScallopedSunCloudPainter({required this.showCloud});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final outerR = size.width * 0.44;
    final innerR = size.width * 0.36;
    const points = 12;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi) / points;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final sunPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFCF4B), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: center, radius: outerR));

    canvas.drawPath(path, sunPaint);

    if (showCloud) {
      final cloudPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFDCE4F2)],
        ).createShader(
            Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.5));

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.54, size.width * 0.68,
            size.height * 0.32),
        Radius.circular(size.width * 0.16),
      );
      canvas.drawRRect(rRect, cloudPaint);
      canvas.drawCircle(Offset(size.width * 0.42, size.height * 0.56),
          size.width * 0.18, cloudPaint);
      canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.58),
          size.width * 0.14, cloudPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScallopedBadgePainter extends CustomPainter {
  final Color color;
  const _ScallopedBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.49;
    final innerR = size.width * 0.43;
    const waves = 12;

    final path = Path();
    const step = (2 * math.pi) / (waves * 2);
    for (int i = 0; i < waves * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final a = i * step;
      final pt =
          Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        final prevA = (i - 0.5) * step;
        final ctrlR = i.isEven ? innerR * 1.04 : outerR * 1.04;
        final ctrl = Offset(center.dx + ctrlR * math.cos(prevA),
            center.dy + ctrlR * math.sin(prevA));
        path.quadraticBezierTo(ctrl.dx, ctrl.dy, pt.dx, pt.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ScallopedBadgePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WavyLiquidPainter extends CustomPainter {
  final double fillRatio;
  final Color waveColor;

  const _WavyLiquidPainter({
    required this.fillRatio,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topY = size.height * (1.0 - fillRatio);
    final path = Path()..moveTo(0, topY);

    const waveCount = 6;
    final segW = size.width / waveCount;
    for (int i = 0; i < waveCount; i++) {
      final x1 = (i + 0.5) * segW;
      final y1 = topY + (i.isEven ? -5.0 : 5.0);
      final x2 = (i + 1.0) * segW;
      path.quadraticBezierTo(x1, y1, x2, topY);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = waveColor);
  }

  @override
  bool shouldRepaint(covariant _WavyLiquidPainter oldDelegate) =>
      oldDelegate.fillRatio != fillRatio || oldDelegate.waveColor != waveColor;
}

class _HorizonArcPainter extends CustomPainter {
  final bool isDark;
  const _HorizonArcPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.56;

    canvas.drawRect(
      Rect.fromLTRWH(0, horizonY, size.width, size.height - horizonY),
      Paint()
        ..color = isDark
            ? const Color(0xFF343B63).withValues(alpha: 0.65)
            : const Color(0xFFBDCEEB).withValues(alpha: 0.7),
    );

    final domePath = Path()
      ..moveTo(size.width * 0.12, horizonY)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.20, size.width * 0.88, horizonY)
      ..close();

    canvas.drawPath(
      domePath,
      Paint()
        ..color = isDark ? const Color(0xFF5674B8) : const Color(0xFF355996),
    );

    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      Paint()
        ..color = isDark ? Colors.white24 : Colors.white
        ..strokeWidth = 2,
    );

    final sunCenter = Offset(size.width * 0.62, size.height * 0.37);
    canvas.drawCircle(sunCenter, 7, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawCircle(
      sunCenter,
      7,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _HorizonArcPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _CircularGaugePainter extends CustomPainter {
  final bool isDark;
  final double progress;

  const _CircularGaugePainter({
    required this.isDark,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    canvas.drawCircle(
      center,
      size.width * 0.49,
      Paint()
        ..color = isDark ? const Color(0xFF282B4A) : const Color(0xFFF6F6FC),
    );

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = isDark ? const Color(0xFF3B4068) : const Color(0xFFD9DFEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = const Color(0xFF335594)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress.clamp(0.1, 1.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.progress != progress;
}
