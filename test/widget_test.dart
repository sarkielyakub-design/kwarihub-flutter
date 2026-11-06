
import 'package:flutter_test/flutter_test.dart';
import 'package:kwarihub/app.dart';
import 'package:flutter/widgets.dart';
void main() {
  testWidgets('KwariHub app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KwariHubApp());

    // Allow the splash screen's 3-second timer to complete.
    await tester.pump(const Duration(seconds: 3));

    // Allow navigation and resulting frames to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(KwariHubApp), findsOneWidget);

    // Dispose the app and its active timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
