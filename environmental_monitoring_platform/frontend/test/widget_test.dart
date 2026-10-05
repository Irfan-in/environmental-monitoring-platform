import 'package:flutter_test/flutter_test.dart';
import 'package:environmental_monitoring_platform/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EnvironmentalMonitoringApp());
    expect(find.byType(EnvironmentalMonitoringApp), findsOneWidget);
  });
}
