class AlertItem {
  final int id;
  final String source;
  final String parameter;
  final double triggeredValue;
  final double thresholdValue;
  final String alertType;
  final String message;
  final DateTime timestamp;
  final bool isAcknowledged;

  AlertItem({
    required this.id,
    required this.source,
    required this.parameter,
    required this.triggeredValue,
    required this.thresholdValue,
    required this.alertType,
    required this.message,
    required this.timestamp,
    required this.isAcknowledged,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as int? ?? 0,
      source: json['source'] as String? ?? 'system',
      parameter: json['parameter'] as String? ?? 'unknown',
      triggeredValue: (json['triggered_value'] as num?)?.toDouble() ?? 0.0,
      thresholdValue: (json['threshold_value'] as num?)?.toDouble() ?? 0.0,
      alertType: json['alert_type'] as String? ?? 'WARN',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
    );
  }
}
