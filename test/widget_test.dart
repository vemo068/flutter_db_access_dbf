import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maj_ged/main.dart';
import 'package:maj_ged/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App shell loads smoke test', (WidgetTester tester) async {
    // Set a wide screen size for desktop layout
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final settingsService = SettingsService();
    await settingsService.loadSettings();

    await tester.pumpWidget(MajGedApp(settingsService: settingsService));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DualBase Manager'), findsOneWidget);
    expect(find.text('DBF (Read-Only)'), findsOneWidget);
    expect(find.text('MS Access (CRUD)'), findsOneWidget);
  });
}
