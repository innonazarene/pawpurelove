// Widget tests for PawureLove app
import 'package:flutter_test/flutter_test.dart';
import 'package:PawureLove/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const PawureLoveApp());
    // Verify splash screen shows app name
    expect(find.text('PawureLove'), findsOneWidget);
  });
}
