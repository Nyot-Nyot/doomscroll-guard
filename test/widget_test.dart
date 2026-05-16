import 'package:doomscrolling_guard/main.dart';
import 'package:doomscrolling_guard/shared/models/permission_state.dart';
import 'package:doomscrolling_guard/shared/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows onboarding multi-step flow on first launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        initialState: AppLaunchState(
          onboardingCompleted: false,
          permissionState: PermissionState.empty(),
          settings: _testSettings(),
        ),
      ),
    );

    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Langkah 1 dari 3'), findsOneWidget);
    expect(find.text('Berikutnya'), findsOneWidget);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Langkah 2 dari 3'), findsOneWidget);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Langkah 3 dari 3'), findsOneWidget);
    expect(find.text('Lanjut ke Setup'), findsOneWidget);
  });

  testWidgets('guard keeps monitoring button disabled before permissions complete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        initialState: AppLaunchState(
          onboardingCompleted: true,
          permissionState: PermissionState.empty(),
          settings: _testSettings(),
        ),
      ),
    );

    expect(find.text('Permission Setup'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(
      ElevatedButton,
      'Mulai Monitoring',
    ));
    expect(button.onPressed, isNull);
  });

  testWidgets('enables monitoring button when all permissions complete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        initialState: AppLaunchState(
          onboardingCompleted: true,
          permissionState: PermissionState(
            accessibilityGranted: true,
            usageAccessGranted: true,
            overlayGranted: true,
            batteryOptimizationIgnored: true,
          ),
          settings: _testSettings(),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.widgetWithText(
      ElevatedButton,
      'Mulai Monitoring',
    ));
    expect(button.onPressed, isNotNull);
  });
}

Settings _testSettings() {
  return Settings(
    targetApps: const <String>[],
    thresholdMinutes: 20,
    monitoringEnabled: true,
    whitelistApps: const <String>[],
    quietHoursStartMinutes: -1,
    quietHoursEndMinutes: -1,
  );
}
