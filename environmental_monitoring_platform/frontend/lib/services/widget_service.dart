import 'package:flutter/services.dart';

class WidgetService {
  static const _channel =
      MethodChannel('com.example.environmental_monitoring_platform/widget');

  static Future<void> update({
    required String indoorTemp,
    required String outdoorTemp,
    required String humidity,
    required String weatherDesc,
    String location = 'Periya, Kerala',
    String updated = '• Live',
  }) async {
    try {
      await _channel.invokeMethod('updateWidgetData', {
        'indoorTemp': indoorTemp,
        'outdoorTemp': outdoorTemp,
        'humidity': humidity,
        'weatherDesc': weatherDesc,
        'location': location,
        'updated': updated,
      });
    } catch (_) {}
  }
}
