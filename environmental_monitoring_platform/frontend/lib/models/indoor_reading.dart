class IndoorReading {
  final int id;
  final String deviceId;
  final double temperature;
  final double humidity;
  final DateTime timestamp;

  IndoorReading({
    required this.id,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory IndoorReading.fromJson(Map<String, dynamic> json) {
    return IndoorReading(
      id: json['id'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? 'esp32_unknown',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'temperature': temperature,
    'humidity': humidity,
    'timestamp': timestamp.toIso8601String(),
  };
}
