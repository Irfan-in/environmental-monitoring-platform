class ChartPoint {
  final DateTime timestamp;
  final double? indoorTemperature;
  final double? indoorHumidity;
  final double? outdoorTemperature;
  final double? outdoorHumidity;

  ChartPoint({
    required this.timestamp,
    this.indoorTemperature,
    this.indoorHumidity,
    this.outdoorTemperature,
    this.outdoorHumidity,
  });

  static DateTime parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    final str = raw.toString().trim();
    if (str.isEmpty) return DateTime.now();
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return parsed.toLocal();
    }
    return DateTime.now();
  }

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      timestamp: parseTimestamp(json['timestamp']),
      indoorTemperature: (json['indoor_temperature'] as num?)?.toDouble(),
      indoorHumidity: (json['indoor_humidity'] as num?)?.toDouble(),
      outdoorTemperature: (json['outdoor_temperature'] as num?)?.toDouble(),
      outdoorHumidity: (json['outdoor_humidity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'indoor_temperature': indoorTemperature,
    'indoor_humidity': indoorHumidity,
    'outdoor_temperature': outdoorTemperature,
    'outdoor_humidity': outdoorHumidity,
  };
}
