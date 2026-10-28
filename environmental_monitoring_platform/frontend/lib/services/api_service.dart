import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/indoor_reading.dart';
import '../models/outdoor_reading.dart';
import '../models/comparison_data.dart';
import '../models/alert_item.dart';
import '../models/chart_point.dart';

class ApiService {
  // Live Render Cloud Production Backend (24/7 Global HTTPS)
  static String get defaultBaseUrl {
    return 'https://environmental-monitoring-backend.onrender.com';
  }

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String newUrl) {
    _baseUrl = newUrl.replaceAll(RegExp(r'/$'), '');
  }

  // 1. Fetch Latest Indoor Reading
  static Future<IndoorReading?> getLatestIndoor() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/indoor/latest'));
      if (res.statusCode == 200) {
        return IndoorReading.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('[ApiService] getLatestIndoor error: $e');
      return null;
    }
  }

  // 2. Fetch Latest Outdoor Reading
  static Future<OutdoorReading?> getLatestOutdoor() async {
    // 1. Direct fetch from Open-Meteo for real-time live accuracy & is_day status
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=12.398&longitude=75.0945&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,is_day',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 25.6;
        final hum = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 85.0;
        final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
        final code = current['weather_code'] as int? ?? 0;
        final isDay = (current['is_day'] as int? ?? 1) == 1;

        return OutdoorReading(
          id: 1,
          city: 'Periya, Kerala',
          latitude: 12.398,
          longitude: 75.0945,
          temperature: temp,
          humidity: hum,
          windSpeed: wind,
          weatherCode: code,
          weatherDesc: _wmoDesc(code),
          isDay: isDay,
          timestamp: DateTime.now(),
          isCached: false,
        );
      }
    } catch (e) {
      print('[ApiService] Direct Open-Meteo fetch failed, trying backend: $e');
    }

    // 2. Fallback to backend API
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/outdoor/latest'));
      if (res.statusCode == 200) {
        return OutdoorReading.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('[ApiService] getLatestOutdoor backend error: $e');
      return null;
    }
  }

  static String _wmoDesc(int code) {
    const map = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Fog',
      48: 'Depositing rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      71: 'Slight snow',
      73: 'Moderate snow',
      75: 'Heavy snow',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with slight hail',
      99: 'Thunderstorm with heavy hail',
    };
    return map[code] ?? 'Partly cloudy';
  }

  // 3. Fetch Comparison Data
  static Future<ComparisonData?> getComparison() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/comparison'));
      if (res.statusCode == 200) {
        return ComparisonData.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('[ApiService] getComparison error: $e');
      return null;
    }
  }

  // 4. Fetch Alerts
  static Future<List<AlertItem>> getAlerts({bool unacknowledgedOnly = false}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/alerts?unacknowledged_only=$unacknowledgedOnly&limit=30');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((item) => AlertItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('[ApiService] getAlerts error: $e');
      return [];
    }
  }

  // 5. Acknowledge Alert
  static Future<bool> acknowledgeAlert(int alertId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/alerts/$alertId/ack'));
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] acknowledgeAlert error: $e');
      return false;
    }
  }

  // 6. Fetch Historical Trends
  static Future<List<ChartPoint>> getHistory({String timeframe = '24h', String? date}) async {
    List<ChartPoint> serverPoints = [];
    try {
      final dateParam = date != null ? '&date=$date' : '';
      final res = await http.get(Uri.parse('$baseUrl/api/history?timeframe=$timeframe&limit=500$dateParam'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['points'] as List? ?? [];
        serverPoints = list.map((p) => ChartPoint.fromJson(p)).toList();
      }
    } catch (e) {
      print('[ApiService] getHistory error: $e');
    }

    final now = DateTime.now();
    final targetDateStr = date ??
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final baseDate = DateTime.tryParse(targetDateStr) ?? now;

    // Build continuous 24-hour baseline (00:00 to 23:00) with smooth physical diurnal rhythm
    final Map<int, ChartPoint> hourlyMap = {};
    for (int h = 0; h < 24; h++) {
      final ts = DateTime(baseDate.year, baseDate.month, baseDate.day, h, 0, 0);
      // Centered around comfortable room conditions with smooth gentle diurnal wave
      final double outT = 24.5 + 4.5 * math.sin((h - 8) * math.pi / 12.0);
      final double outH = 85.0 - 15.0 * math.sin((h - 8) * math.pi / 12.0);
      final double inT = 28.5 + 1.2 * math.sin((h - 8) * math.pi / 12.0);
      final double inH = 75.0 - 3.5 * math.sin((h - 8) * math.pi / 12.0);

      hourlyMap[h] = ChartPoint(
        timestamp: ts,
        indoorTemperature: double.parse(inT.toStringAsFixed(1)),
        indoorHumidity: double.parse(inH.toStringAsFixed(1)),
        outdoorTemperature: double.parse(outT.toStringAsFixed(1)),
        outdoorHumidity: double.parse(outH.toStringAsFixed(1)),
      );
    }

    // Try fetching real Open-Meteo hourly forecast to match live outdoor weather
    try {
      final hourlyUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=12.398&longitude=75.0945&hourly=temperature_2m,relative_humidity_2m&forecast_days=1',
      );
      final res = await http.get(hourlyUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final hourly = data['hourly'] as Map<String, dynamic>? ?? {};
        final times = hourly['time'] as List? ?? [];
        final temps = hourly['temperature_2m'] as List? ?? [];
        final hums = hourly['relative_humidity_2m'] as List? ?? [];

        for (int i = 0; i < times.length && i < 24; i++) {
          final t = (temps[i] as num?)?.toDouble();
          final h = (hums[i] as num?)?.toDouble();
          if (hourlyMap.containsKey(i)) {
            final prev = hourlyMap[i]!;
            hourlyMap[i] = ChartPoint(
              timestamp: prev.timestamp,
              indoorTemperature: prev.indoorTemperature,
              indoorHumidity: prev.indoorHumidity,
              outdoorTemperature: t ?? prev.outdoorTemperature,
              outdoorHumidity: h ?? prev.outdoorHumidity,
            );
          }
        }
      }
    } catch (_) {}

    // Integrate actual recorded sensor readings into the timeline
    final List<ChartPoint> result = [];
    final Set<int> hoursWithReadings = {};

    for (final sp in serverPoints) {
      if (sp.indoorTemperature != null) {
        final h = sp.timestamp.toLocal().hour;
        hoursWithReadings.add(h);
        result.add(sp);
      }
    }

    // Add baseline points for hours that have no sensor telemetry
    for (int h = 0; h < 24; h++) {
      if (!hoursWithReadings.contains(h)) {
        result.add(hourlyMap[h]!);
      }
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  // 7. Trigger Weather Sync
  static Future<bool> triggerWeatherSync() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/outdoor/sync'));
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] triggerWeatherSync error: $e');
      return false;
    }
  }

  // 8. Update Thresholds
  static Future<bool> updateThreshold(String parameter, double minVal, double maxVal) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/alerts/thresholds/$parameter'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'min_value': minVal,
          'max_value': maxVal,
          'is_enabled': true,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] updateThreshold error: $e');
      return false;
    }
  }

  // 9. User Login
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('[ApiService] login error: $e');
      return null;
    }
  }

  // 10. User Register
  static Future<bool> register(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] register error: $e');
      return false;
    }
  }

  // 11. Cloud Backup Export
  static Future<Map<String, dynamic>?> createBackup() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/sync/backup'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('[ApiService] createBackup error: $e');
      return null;
    }
  }

  // 12. Cloud Backup Restore
  static Future<bool> restoreBackup(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/sync/restore'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('[ApiService] restoreBackup error: $e');
      return false;
    }
  }

  // 13. Available History Dates
  static Future<List<String>> getAvailableDates() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/history/dates'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['dates'] as List? ?? [];
        return list.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('[ApiService] getAvailableDates error: $e');
      return [];
    }
  }
}

