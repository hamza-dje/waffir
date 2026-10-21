import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';

void main() {
  testWidgets('renew an expired period and retain history after restart',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final oldStart = DateTime.now().subtract(const Duration(days: 7));
    SharedPreferences.setMockInitialValues({
      'budget_state': jsonEncode({
        'budget': 700,
        'days': 7,
        'start': oldStart.toIso8601String(),
        'expenses': [
          {
            'label': 'Old expense',
            'amount': 70,
            'date': oldStart.toIso8601String()
          }
        ],
      })
    });
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect(find.text('Your budget period has ended.'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Coffee\n50 DZD'))
            .onPressed,
        isNull);
    await tester.tap(find.text('Start new period'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1400');
    await tester.ensureVisible(find.text('Confirm new period'));
    await tester.tap(find.text('Confirm new period'));
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Old expense'), findsOneWidget);
    expect(find.text('0 DZD spent this period'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Old expense'), findsOneWidget);
  });
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
