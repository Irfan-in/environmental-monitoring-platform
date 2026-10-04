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

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      indoorTemperature: (json['indoor_temperature'] as num?)?.toDouble(),
      indoorHumidity: (json['indoor_humidity'] as num?)?.toDouble(),
      outdoorTemperature: (json['outdoor_temperature'] as num?)?.toDouble(),
      outdoorHumidity: (json['outdoor_humidity'] as num?)?.toDouble(),
    );
  }
}
