import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_tool_app/screens/main_screen.dart';
import 'package:qr_tool_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test loads NavigationBar destinations', (WidgetTester tester) async {
    // SharedPreferences mock üçün ilkin dəyərlər
    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    await tester.pumpWidget(MaterialApp(
      home: MainScreen(storageService: storageService),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Naviqasiya elementlərinin mövcudluğunu yoxlayırıq
    expect(find.text('Skaner'), findsOneWidget);
    expect(find.text('Generator'), findsOneWidget);
    expect(find.text('Tarixçə'), findsOneWidget);
    expect(find.text('Tənzimləmələr'), findsOneWidget);
  });

  testWidgets('Pixel 3 screen size (393x786) renders all tabs without overflow',
      (WidgetTester tester) async {
    // Pixel 3 dimensions
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final storageService = StorageService();
    await storageService.init();

    await tester.pumpWidget(MaterialApp(
      home: MainScreen(storageService: storageService),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    // Skaner tab-ı yoxlayırıq
    expect(find.text('QR Skaner'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Generator tab-ına keçid
    await tester.tap(find.text('Generator'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('QR Generator'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tarixçə tab-ına keçid
    await tester.tap(find.text('Tarixçə'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tarixçə'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Tənzimləmələr tab-ına keçid
    await tester.tap(find.text('Tənzimləmələr'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tənzimləmələr'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
