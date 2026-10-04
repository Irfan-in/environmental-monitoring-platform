class OutdoorReading {
  final int id;
  final String city;
  final double latitude;
  final double longitude;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final String weatherDesc;
  final DateTime timestamp;

  OutdoorReading({
    required this.id,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.weatherDesc,
    required this.timestamp,
  });

  factory OutdoorReading.fromJson(Map<String, dynamic> json) {
    return OutdoorReading(
      id: json['id'] as int? ?? 0,
      city: json['city'] as String? ?? 'Outdoor Location',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      weatherCode: json['weather_code'] as int? ?? 0,
      weatherDesc: json['weather_desc'] as String? ?? 'Fair',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
