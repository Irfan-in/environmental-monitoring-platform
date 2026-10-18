import 'dart:async';
import 'package:flutter/material.dart';
import '../models/indoor_reading.dart';
import '../models/outdoor_reading.dart';
import '../models/comparison_data.dart';
import '../models/alert_item.dart';
import '../models/chart_point.dart';
import '../services/api_service.dart';

class EnvironmentProvider with ChangeNotifier {
  IndoorReading? _indoorReading;
  OutdoorReading? _outdoorReading;
  ComparisonData? _comparisonData;
  List<AlertItem> _alerts = [];
  List<ChartPoint> _historyPoints = [];

  bool _isLoading = false;
  bool _isSyncingWeather = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  DateTime? _lastWeatherSyncTime;

  // Theme State: Default to Dark Mode
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  // User Auth State: Default to logged-in Admin (zero barrier)
  String _username = 'Admin';
  String _userRole = 'admin'; // 'admin' or 'viewer'
  bool _isLoggedIn = true;

  // Realme-Style Calendar Date Navigation
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  bool get isSelectedDateToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  // Getters
  IndoorReading? get indoorReading => _indoorReading;
  OutdoorReading? get outdoorReading => _outdoorReading;
  ComparisonData? get comparisonData => _comparisonData;
  List<AlertItem> get alerts => _alerts;
  List<ChartPoint> get historyPoints => _historyPoints;
  bool get isLoading => _isLoading;
  bool get isSyncingWeather => _isSyncingWeather;
  String? get errorMessage => _errorMessage;

  String get username => _username;
  String get userRole => _userRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _userRole == 'admin';

  int get unacknowledgedAlertCount =>
      _alerts.where((a) => !a.isAcknowledged).length;

  EnvironmentProvider() {
    // Initialize with a realistic resilient weather fallback so weather is NEVER blank (-- °C)
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

    startAutoPolling();
  }

  void startAutoPolling({Duration interval = const Duration(seconds: 4)}) {
    _pollingTimer?.cancel();
    fetchData(); // Initial fetch
    _pollingTimer = Timer.periodic(interval, (_) => fetchData(silent: true));
  }

  void stopAutoPolling() {
    _pollingTimer?.cancel();
  }

  // Realme Calendar Navigation Methods
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
      final points = await ApiService.getHistory(timeframe: '24h', date: dateStr);
      if (points.isNotEmpty) {
        _historyPoints = points;
        notifyListeners();
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

      final results = await Future.wait([
        ApiService.getLatestIndoor(),
        ApiService.getLatestOutdoor(),
        ApiService.getComparison(),
        ApiService.getAlerts(),
        ApiService.getHistory(date: dateStr),
      ]);

      if (results[0] != null) {
        _indoorReading = results[0] as IndoorReading?;
      }

      // Offline Weather Resilience: NEVER blank out outdoor weather
      final fetchedOutdoor = results[1] as OutdoorReading?;
      if (fetchedOutdoor != null) {
        _outdoorReading = fetchedOutdoor;
      } else if (_outdoorReading != null) {
        // Retain cached reading with cached flag
        _outdoorReading = OutdoorReading(
          id: _outdoorReading!.id,
          city: _outdoorReading!.city,
          latitude: _outdoorReading!.latitude,
          longitude: _outdoorReading!.longitude,
          temperature: _outdoorReading!.temperature,
          humidity: _outdoorReading!.humidity,
          windSpeed: _outdoorReading!.windSpeed,
          weatherCode: _outdoorReading!.weatherCode,
          weatherDesc: _outdoorReading!.weatherDesc,
          timestamp: _outdoorReading!.timestamp,
          isCached: true,
          cachedAt: _outdoorReading!.cachedAt ?? DateTime.now(),
        );
      }

      if (results[2] != null) {
        _comparisonData = results[2] as ComparisonData?;
      }
      _alerts = results[3] as List<AlertItem>;
      
      final points = results[4] as List<ChartPoint>;
      if (points.isNotEmpty || _historyPoints.isEmpty) {
        _historyPoints = points;
      }

      _errorMessage = null;

      // Silent Automatic Weather Sync every 15 minutes if online
      final now = DateTime.now();
      if (_lastWeatherSyncTime == null || now.difference(_lastWeatherSyncTime!).inMinutes >= 15) {
        _lastWeatherSyncTime = now;
        ApiService.triggerWeatherSync();
      }
    } catch (e) {
      _errorMessage = e.toString();
      // Ensure outdoor reading is never null on error
      _outdoorReading ??= OutdoorReading(
        id: 0,
        city: 'Offline Cached Weather',
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
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
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
    final success = await ApiService.acknowledgeAlert(id);
    if (success) {
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = AlertItem(
          id: _alerts[index].id,
          source: _alerts[index].source,
          parameter: _alerts[index].parameter,
          triggeredValue: _alerts[index].triggeredValue,
          thresholdValue: _alerts[index].thresholdValue,
          alertType: _alerts[index].alertType,
          message: _alerts[index].message,
          timestamp: _alerts[index].timestamp,
          isAcknowledged: true,
        );
        notifyListeners();
      }
    }
  }

  Future<String?> login(String username, String password) async {
    final res = await ApiService.login(username, password);
    if (res != null && res['success'] == true) {
      _username = res['username'] ?? username;
      _userRole = res['role'] ?? 'viewer';
      _isLoggedIn = true;
      notifyListeners();
      return null;
    }
    return 'Invalid username or password';
  }

  void logout() {
    _username = 'Guest';
    _userRole = 'viewer';
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> backupToCloud() async {
    final data = await ApiService.createBackup();
    return data != null;
  }

  Future<bool> restoreFromCloud() async {
    final data = await ApiService.createBackup();
    if (data != null) {
      final success = await ApiService.restoreBackup(data);
      if (success) {
        await fetchData(silent: true);
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
