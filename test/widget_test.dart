// Widget tests for PawPureLove app
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpurelove/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PawPureLoveApp());
    // Verify splash screen shows app name
    expect(find.text('PawPureLove'), findsOneWidget);
  });
}
