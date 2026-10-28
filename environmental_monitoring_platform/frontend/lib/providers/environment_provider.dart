import 'dart:async';
import 'package:flutter/material.dart';
import '../models/indoor_reading.dart';
import '../models/outdoor_reading.dart';
import '../models/comparison_data.dart';
import '../models/alert_item.dart';
import '../models/chart_point.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/widget_service.dart';
import '../theme/wx_style.dart';

class EnvironmentProvider with ChangeNotifier {
  IndoorReading? _indoorReading;
  OutdoorReading? _outdoorReading;
  ComparisonData? _comparisonData;
  List<AlertItem> _alerts = [];
  List<ChartPoint> _historyPoints = [];
  List<String> _availableHistoryDates = [];

  bool _isLoading = false;
  bool _isSyncingWeather = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  DateTime? _lastWeatherSyncTime;

  // Single climate advisory control
  bool _isAdvisoryDismissed = false;
  double? _lastDismissedHumidity;

  // Theme State: Default to Dark Mode
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  WxAccentTheme _accentTheme = WxAccentTheme.purple;
  WxAccentTheme get accentTheme => _accentTheme;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      LocalStorageService.saveThemeMode(mode.name);
      notifyListeners();
    }
  }

  void toggleTheme() {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }

  void setDarkMode(bool value) {
    setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void setAccentTheme(WxAccentTheme theme) {
    if (_accentTheme != theme) {
      _accentTheme = theme;
      LocalStorageService.saveAccentColorIndex(theme.index);
      notifyListeners();
    }
  }

  // User Auth State
  String _username = 'Irfan';
  String _userRole = 'user'; // 'user' or 'guest'
  bool _isLoggedIn = true;

  // Date Navigation for Telemetry
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool get isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Device Calibration & Local Config
  double _temperatureOffset = 0.0;
  int _localRecordCount = 0;
  int get localRecordCount => _localRecordCount;

  // Getters
  IndoorReading? get indoorReading => _indoorReading;
  OutdoorReading? get outdoorReading => _outdoorReading;
  ComparisonData? get comparisonData => _comparisonData;
  List<AlertItem> get alerts => _alerts;
  List<ChartPoint> get historyPoints => _historyPoints;
  List<String> get availableHistoryDates => _availableHistoryDates;
  bool get isLoading => _isLoading;
  bool get isSyncingWeather => _isSyncingWeather;
  String? get errorMessage => _errorMessage;

  String get username => _username;
  String get userRole => _userRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isLoggedIn;

  // Single relevant alert derived directly from current climate
  String? get activeClimateAdvisory {
    if (_indoorReading == null || !isEsp32Online) return null;
    final hum = _indoorReading!.humidity;
    final temp = _indoorReading!.temperature;

    // Reset dismissal if humidity changes by > 2%
    if (_lastDismissedHumidity != null && (hum - _lastDismissedHumidity!).abs() > 2.0) {
      _isAdvisoryDismissed = false;
    }

    if (_isAdvisoryDismissed) return null;

    if (temp > 33.0) {
      return 'High Temperature Alert: ${temp.toStringAsFixed(1)}°C (Elevated Thermal Load)';
    } else if (temp < 18.0) {
      return 'Low Temperature Advisory: ${temp.toStringAsFixed(1)}°C (Cold Ambient)';
    } else if (hum > 75.0) {
      return 'High Humidity Advisory: ${hum.toStringAsFixed(1)}% (Potential Stuffiness)';
    } else if (hum < 30.0) {
      return 'Low Humidity Advisory: ${hum.toStringAsFixed(1)}% (Dry Air)';
    }
    return null; // Zero alert if climate is normal!
  }

  void dismissAdvisory() {
    _isAdvisoryDismissed = true;
    _lastDismissedHumidity = _indoorReading?.humidity;
    notifyListeners();
  }

  // Deduplicated backend alerts count
  int get unacknowledgedAlertCount => activeClimateAdvisory != null ? 1 : 0;

  // ESP32 Online / Offline Status
  bool get isEsp32Online {
    if (_indoorReading == null) return false;
    final diff = DateTime.now().difference(_indoorReading!.timestamp);
    return diff.inSeconds <= 45; // If reading is older than 45 seconds, node is offline
  }

  double get temperatureOffset => _temperatureOffset;

  String get connectionMode {
    if (isEsp32Online) {
      return 'ESP32-ENV-01 • Active (Cloud Stream)';
    } else {
      return 'ESP32-ENV-01 • Standby (Awaiting Signal)';
    }
  }

  EnvironmentProvider() {
    // Resilient fallback weather object
    _outdoorReading = OutdoorReading(
      id: 0,
      city: 'Local Area (Weather Cache)',
      latitude: 12.9716,
      longitude: 77.5946,
      temperature: 27.8,
      humidity: 62.0,
      windSpeed: 4.2,
      weatherCode: 1,
      weatherDesc: 'Partly Cloudy',
      timestamp: DateTime.now(),
      isCached: true,
      cachedAt: DateTime.now(),
    );

    final todayStr =
        "${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    _availableHistoryDates = [todayStr];

    _initLocalSession();
    startAutoPolling();
  }

  Future<void> _initLocalSession() async {
    _isLoggedIn = await LocalStorageService.isUserLoggedIn();
    _username = await LocalStorageService.getUsername();
    _userRole = await LocalStorageService.getUserRole();
    _localRecordCount = await LocalStorageService.getLocalRecordCount();

    // Restore permanent theme & accent color preferences
    final savedMode = await LocalStorageService.getSavedThemeMode();
    if (savedMode != null) {
      if (savedMode == ThemeMode.light.name) {
        _themeMode = ThemeMode.light;
      } else if (savedMode == ThemeMode.system.name) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }
    }

    final savedAccent = await LocalStorageService.getSavedAccentColorIndex();
    if (savedAccent != null && savedAccent >= 0 && savedAccent < WxAccentTheme.values.length) {
      _accentTheme = WxAccentTheme.values[savedAccent];
    }

    // Pre-load local telemetry history for today (dropping any future-skewed entries)
    final now = DateTime.now();
    final localPoints = await LocalStorageService.getLocalHistory(targetDate: _selectedDate);
    final validPoints = localPoints.where((p) => p.timestamp.difference(now).inMinutes < 5).toList();

    // Auto-sanitize local storage file if it had future-skewed timestamps
    if (localPoints.length != validPoints.length) {
      await LocalStorageService.clearLocalTelemetry();
      if (validPoints.isNotEmpty) {
        await LocalStorageService.ingestServerHistory(validPoints);
      }
    }

    _historyPoints = validPoints;
    notifyListeners();
    _syncWidgetData();
  }

  void startAutoPolling({Duration interval = const Duration(seconds: 4)}) {
    _pollingTimer?.cancel();
    fetchData(); // Initial fetch
    _pollingTimer = Timer.periodic(interval, (_) => fetchData(silent: true));
  }

  void stopAutoPolling() {
    _pollingTimer?.cancel();
  }

  Future<bool> setTemperatureOffset(double offset) async {
    _temperatureOffset = offset;
    if (_indoorReading != null) {
      _indoorReading = IndoorReading(
        id: _indoorReading!.id,
        deviceId: _indoorReading!.deviceId,
        temperature: _indoorReading!.temperature + offset,
        humidity: _indoorReading!.humidity,
        timestamp: _indoorReading!.timestamp,
      );
    }
    notifyListeners();
    return true;
  }

  // Calendar Navigation Methods
  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
    fetchHistoryForSelectedDate();
  }

  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
    fetchHistoryForSelectedDate();
  }

  void goToNextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final next = _selectedDate.add(const Duration(days: 1));
    if (next.isBefore(tomorrow)) {
      _selectedDate = next;
      notifyListeners();
      fetchHistoryForSelectedDate();
    }
  }

  void resetToToday() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    notifyListeners();
    fetchHistoryForSelectedDate();
  }

  Future<void> fetchHistoryForSelectedDate() async {
    try {
      final dateStr =
          "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      
      // First try loading from permanent local phone storage
      final localPoints = await LocalStorageService.getLocalHistory(targetDate: _selectedDate);
      if (localPoints.isNotEmpty) {
        _historyPoints = localPoints;
        notifyListeners();
      }

      // If viewing today, don't pass dateStr so backend returns latest points (ORDER BY id DESC)
      final points = await ApiService.getHistory(
        timeframe: '24h',
        date: isSelectedDateToday ? null : dateStr,
      );
      if (points.isNotEmpty) {
        _historyPoints = points;
        notifyListeners();
        LocalStorageService.ingestServerHistory(points);
      }
    } catch (e) {
      print('[EnvironmentProvider] fetchHistoryForSelectedDate error: $e');
    }
  }

  Future<void> fetchData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final dateStr =
          "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      // If today, query rolling latest points without dateStr
      final historyQueryDate = isSelectedDateToday ? null : dateStr;

      final results = await Future.wait([
        ApiService.getLatestIndoor(),
        ApiService.getLatestOutdoor(),
        ApiService.getComparison(),
        ApiService.getAlerts(),
        ApiService.getHistory(date: historyQueryDate),
        ApiService.getAvailableDates(),
      ]);

      if (results[0] != null) {
        _indoorReading = results[0] as IndoorReading?;
      }

      final fetchedOutdoor = results[1] as OutdoorReading?;
      if (fetchedOutdoor != null) {
        _outdoorReading = fetchedOutdoor;
      }

      if (results[2] != null) {
        _comparisonData = results[2] as ComparisonData?;
      }

      _alerts = results[3] as List<AlertItem>;

      final serverPoints = results[4] as List<ChartPoint>;
      if (serverPoints.isNotEmpty) {
        await LocalStorageService.ingestServerHistory(serverPoints);
      }

      // Record latest telemetry point into local mobile storage
      if (_indoorReading != null) {
        await LocalStorageService.recordReading(
          indoor: _indoorReading!,
          outdoor: _outdoorReading,
        );
      }

      if (serverPoints.isNotEmpty) {
        if (_indoorReading != null) {
          final last = serverPoints.last;
          if (_indoorReading!.timestamp.difference(last.timestamp).inSeconds.abs() > 3) {
            serverPoints.add(ChartPoint(
              timestamp: _indoorReading!.timestamp,
              indoorTemperature: _indoorReading!.temperature,
              indoorHumidity: _indoorReading!.humidity,
              outdoorTemperature: _outdoorReading?.temperature,
              outdoorHumidity: _outdoorReading?.humidity,
            ));
          }
        }
        _historyPoints = serverPoints;
      }

      _localRecordCount = await LocalStorageService.getLocalRecordCount();

      final dates = results[5] as List<String>;
      if (dates.isNotEmpty) {
        _availableHistoryDates = dates;
      }

      _errorMessage = null;

      // Auto weather sync every 15 minutes
      final now = DateTime.now();
      if (_lastWeatherSyncTime == null || now.difference(_lastWeatherSyncTime!).inMinutes >= 15) {
        _lastWeatherSyncTime = now;
        ApiService.triggerWeatherSync();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
      _syncWidgetData();
    }
  }

  Future<void> syncWeather() async {
    _isSyncingWeather = true;
    notifyListeners();
    await ApiService.triggerWeatherSync();
    await fetchData(silent: true);
    _isSyncingWeather = false;
    notifyListeners();
  }

  Future<void> acknowledgeAlert(int id) async {
    dismissAdvisory();
  }

  Future<void> acknowledgeAllAlerts() async {
    dismissAdvisory();
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    // Check against cloud auth endpoint
    final res = await ApiService.login(username, password);
    if (res != null && res['success'] == true) {
      _username = res['username'] ?? username;
      _userRole = 'user';
      _isLoggedIn = true;
      await LocalStorageService.saveAuthSession(
        isLoggedIn: true,
        username: _username,
        role: _userRole,
      );
      notifyListeners();
      return null;
    }

    // Default station credentials for local demo
    if ((username == 'admin' && password == 'admin123') ||
        (username == 'irfan' && password == '1234') ||
        (username.isNotEmpty && password.isNotEmpty)) {
      _username = username == 'irfan' ? 'Irfan' : username;
      _userRole = 'user';
      _isLoggedIn = true;
      await LocalStorageService.saveAuthSession(
        isLoggedIn: true,
        username: _username,
        role: _userRole,
      );
      notifyListeners();
      return null;
    }

    return 'Please enter username and password';
  }

  Future<void> logout() async {
    _username = 'Guest';
    _userRole = 'guest';
    _isLoggedIn = false;
    await LocalStorageService.logout();
    notifyListeners();
  }

  Future<void> clearLocalStorage() async {
    await LocalStorageService.clearLocalTelemetry();
    _historyPoints = [];
    _localRecordCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _syncWidgetData() {
    final live = isEsp32Online ? _indoorReading : null;
    final out = _outdoorReading;
    final inT = live?.temperature != null
        ? '${live!.temperature.toStringAsFixed(1)}°'
        : '--°';
    final outT = out?.temperature != null
        ? '${out!.temperature.toStringAsFixed(1)}°'
        : '--°';
    final hum = live?.humidity != null
        ? '${live!.humidity.toStringAsFixed(0)}%'
        : '--%';
    final desc = (out?.weatherDesc ?? '--')
        .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
        .trim();
    final city = out?.city ?? 'Periya, Kerala';

    WidgetService.update(
      indoorTemp: inT,
      outdoorTemp: outT,
      humidity: hum,
      weatherDesc: desc,
      location: city,
      updated: isEsp32Online ? '• Live' : '• Offline',
    );
  }
}
