// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:pocket_doctor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PocketDoctorApp());
    // Allow SplashScreen delayed animations/timers to settle.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that the splash screen is displayed
    expect(find.text('Pocket Doctor'), findsOneWidget);
    expect(find.text('Your AI Health Companion'), findsOneWidget);
  });
}
