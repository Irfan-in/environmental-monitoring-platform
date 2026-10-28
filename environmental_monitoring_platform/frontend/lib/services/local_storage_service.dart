import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chart_point.dart';
import '../models/indoor_reading.dart';
import '../models/outdoor_reading.dart';

class LocalStorageService {
  static const String _authKey = 'env_auth_user';
  static const String _roleKey = 'env_auth_role';
  static const String _isLoggedInKey = 'env_is_logged_in';
  static const String _telemetryFileName = 'local_telemetry_repository.json';

  static File? _localFile;

  /// Initialize file handle
  static Future<File> _getFile() async {
    if (_localFile != null) return _localFile!;
    final directory = await getApplicationDocumentsDirectory();
    _localFile = File('${directory.path}/$_telemetryFileName');
    if (!await _localFile!.exists()) {
      await _localFile!.writeAsString(jsonEncode([]));
    }
    return _localFile!;
  }

  /// Append a new indoor + outdoor reading pair to local permanent repository
  static Future<void> recordReading({
    required IndoorReading indoor,
    OutdoorReading? outdoor,
  }) async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      List<dynamic> list = [];
      try {
        list = jsonDecode(content) as List<dynamic>;
      } catch (_) {
        list = [];
      }

      // Avoid duplicate recordings within 3 seconds
      final nowIso = indoor.timestamp.toIso8601String();
      if (list.isNotEmpty) {
        final lastEntry = list.last as Map<String, dynamic>;
        final lastTs = DateTime.tryParse(lastEntry['timestamp'] ?? '');
        if (lastTs != null &&
            indoor.timestamp.difference(lastTs).inSeconds.abs() < 3) {
          return;
        }
      }

      final newEntry = {
        'timestamp': nowIso,
        'indoor_temperature': indoor.temperature,
        'indoor_humidity': indoor.humidity,
        'outdoor_temperature': outdoor?.temperature,
        'outdoor_humidity': outdoor?.humidity,
      };

      list.add(newEntry);

      // Keep up to 20,000 points locally (sufficient for months of continuous history)
      if (list.length > 20000) {
        list = list.sublist(list.length - 20000);
      }

      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      print('[LocalStorageService] recordReading error: $e');
    }
  }

  /// Bulk ingest points from server buffer to ensure no gaps
  static Future<void> ingestServerHistory(List<ChartPoint> serverPoints) async {
    if (serverPoints.isEmpty) return;
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      List<dynamic> list = [];
      try {
        list = jsonDecode(content) as List<dynamic>;
      } catch (_) {
        list = [];
      }

      final Set<String> existingTimestamps = list
          .map((e) => (e as Map<String, dynamic>)['timestamp']?.toString() ?? '')
          .toSet();

      bool modified = false;
      for (final p in serverPoints) {
        final tsIso = p.timestamp.toIso8601String();
        if (!existingTimestamps.contains(tsIso)) {
          list.add({
            'timestamp': tsIso,
            'indoor_temperature': p.indoorTemperature,
            'indoor_humidity': p.indoorHumidity,
            'outdoor_temperature': p.outdoorTemperature,
            'outdoor_humidity': p.outdoorHumidity,
          });
          existingTimestamps.add(tsIso);
          modified = true;
        }
      }

      if (modified) {
        // Sort chronologically
        list.sort((a, b) {
          final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
          final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
          return ta.compareTo(tb);
        });

        if (list.length > 20000) {
          list = list.sublist(list.length - 20000);
        }

        await file.writeAsString(jsonEncode(list));
      }
    } catch (e) {
      print('[LocalStorageService] ingestServerHistory error: $e');
    }
  }

  /// Retrieve local history points for a specific date (or today)
  static Future<List<ChartPoint>> getLocalHistory({DateTime? targetDate}) async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List<dynamic>;
      final date = targetDate ?? DateTime.now();

      final filtered = list.where((entry) {
        final map = entry as Map<String, dynamic>;
        final ts = ChartPoint.parseTimestamp(map['timestamp']);
        return ts.year == date.year && ts.month == date.month && ts.day == date.day;
      }).map((e) {
        final map = e as Map<String, dynamic>;
        return ChartPoint.fromJson(map);
      }).toList();

      return filtered;
    } catch (e) {
      print('[LocalStorageService] getLocalHistory error: $e');
      return [];
    }
  }

  /// Get total count of locally stored telemetry records
  static Future<int> getLocalRecordCount() async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  /// Clear local telemetry database
  static Future<void> clearLocalTelemetry() async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode([]));
    } catch (e) {
      print('[LocalStorageService] clearLocalTelemetry error: $e');
    }
  }

  static const String _themeModeKey = 'app_theme_mode';
  static const String _accentColorKey = 'app_accent_color_index';

  // --- Auth & Session Persistence ---

  static Future<String?> getSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  static Future<int?> getSavedAccentColorIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_accentColorKey);
  }

  static Future<void> saveAccentColorIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, index);
  }

  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? true;
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authKey) ?? 'Irfan';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? 'admin';
  }

  static Future<void> saveAuthSession({
    required bool isLoggedIn,
    required String username,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setString(_authKey, username);
    await prefs.setString(_roleKey, role);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setString(_authKey, 'Guest');
    await prefs.setString(_roleKey, 'viewer');
  }
}
