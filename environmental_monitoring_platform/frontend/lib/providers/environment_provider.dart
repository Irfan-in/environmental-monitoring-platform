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

  // User Auth State (Guest by default, never forced)
  String _username = 'Guest';
  String _userRole = 'viewer'; // 'admin' or 'viewer'
  bool _isLoggedIn = false;

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

  Future<void> fetchData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        ApiService.getLatestIndoor(),
        ApiService.getLatestOutdoor(),
        ApiService.getComparison(),
        ApiService.getAlerts(),
        ApiService.getHistory(),
      ]);

      _indoorReading = results[0] as IndoorReading?;
      _outdoorReading = results[1] as OutdoorReading?;
      _comparisonData = results[2] as ComparisonData?;
      _alerts = results[3] as List<AlertItem>;
      _historyPoints = results[4] as List<ChartPoint>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
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
      return null; // success, no error message
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
