import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:travel_safety_app/main.dart';

void main() {
  setUp(() {
    // Provide an empty SharedPreferences store so each test starts fresh.
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper: pumps the app and then drains the splash timer so no
  /// pending timers remain when the test ends.
  Future<void> pumpAppAndDrainSplash(WidgetTester tester) async {
    await tester.pumpWidget(const TravelSafetyApp());
    await tester.pump(); // build initial widget tree
  }

  Future<void> drainSplash(WidgetTester tester) async {
    // Advance virtual clock past the 1800 ms splash delay.
    await tester.pump(const Duration(seconds: 2));
    // Let navigation and any subsequent frames settle.
    await tester.pumpAndSettle();
  }

  testWidgets('Splash screen shows app name', (tester) async {
    await pumpAppAndDrainSplash(tester);

    expect(find.text('Travel Safety'), findsOneWidget);

    await drainSplash(tester);
  });

  testWidgets('Splash screen shows tagline', (tester) async {
    await pumpAppAndDrainSplash(tester);

    expect(find.text('Your journey, always protected.'), findsOneWidget);

    await drainSplash(tester);
  });

  testWidgets('Splash navigates to registration when no account exists',
      (tester) async {
    // No account in mock store → splash should navigate to /register.
    await pumpAppAndDrainSplash(tester);
    await drainSplash(tester);

    // Registration step 1 heading should be visible.
    expect(find.text('Create Account'), findsOneWidget);
  });
}
