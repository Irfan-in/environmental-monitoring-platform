import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/indoor_reading.dart';
import '../models/outdoor_reading.dart';
import '../models/comparison_data.dart';
import '../models/alert_item.dart';
import '../models/chart_point.dart';

class ApiService {
  // Defaults to localhost on the phone (where Pydroid 3 runs)
  static String get defaultBaseUrl {
    return 'http://127.0.0.1:8080';
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
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/outdoor/latest'));
      if (res.statusCode == 200) {
        return OutdoorReading.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      print('[ApiService] getLatestOutdoor error: $e');
      return null;
    }
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
  static Future<List<ChartPoint>> getHistory({String timeframe = '24h'}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/history?timeframe=$timeframe&limit=30'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['points'] as List? ?? [];
        return list.map((p) => ChartPoint.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print('[ApiService] getHistory error: $e');
      return [];
    }
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
}
