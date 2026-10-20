import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';

void main() {
  testWidgets('budget, expense and history survive app restart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9000');
    await tester.ensureVisible(find.text('Start my budget'));
    await tester.tap(find.text('Start my budget'));
    await tester.pumpAndSettle();
    expect(find.text('300'), findsOneWidget);
    await tester.tap(find.text('Coffee\n50 DZD'));
    await tester.pumpAndSettle();
    expect(find.text('298'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('50 DZD spent this period'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect(find.text('298'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
  });
}
