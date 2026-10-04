import 'indoor_reading.dart';
import 'outdoor_reading.dart';

class ComparisonData {
  final IndoorReading? indoor;
  final OutdoorReading? outdoor;
  final double? tempDiff;
  final double? humDiff;
  final double? indoorHeatIndex;
  final double? outdoorHeatIndex;
  final String comfortAssessment;
  final String statusSummary;

  ComparisonData({
    this.indoor,
    this.outdoor,
    this.tempDiff,
    this.humDiff,
    this.indoorHeatIndex,
    this.outdoorHeatIndex,
    required this.comfortAssessment,
    required this.statusSummary,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      indoor: json['indoor'] != null
          ? IndoorReading.fromJson(json['indoor'] as Map<String, dynamic>)
          : null,
      outdoor: json['outdoor'] != null
          ? OutdoorReading.fromJson(json['outdoor'] as Map<String, dynamic>)
          : null,
      tempDiff: (json['temp_diff'] as num?)?.toDouble(),
      humDiff: (json['hum_diff'] as num?)?.toDouble(),
      indoorHeatIndex: (json['indoor_heat_index'] as num?)?.toDouble(),
      outdoorHeatIndex: (json['outdoor_heat_index'] as num?)?.toDouble(),
      comfortAssessment: json['comfort_assessment'] as String? ?? 'Evaluating...',
      statusSummary: json['status_summary'] as String? ?? 'No summary available.',
    );
  }
}
