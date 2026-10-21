import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';

void main() {
  testWidgets(
      'edit reserves without counting expenses twice, then restore goal',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'budget_state': jsonEncode({
        'budget': 9000,
        'days': 30,
        'start': DateTime.now().toIso8601String(),
        'expenses': [
          {
            'label': 'Coffee',
            'amount': 50,
            'date': DateTime.now().toIso8601String()
          }
        ],
      })
    });
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Budget settings'));
    await tester.pumpAndSettle();
    Future<void> field(String label, String value) async {
      final finder = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
    }

    await field('Fixed costs', '9500');
    await tester.ensureVisible(find.text('Save budget'));
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(find.text('Fixed costs and savings exceed total funds.'),
        findsOneWidget);
    await field('Fixed costs', '2500');
    await field('Savings reserved', '1000');
    await field('Savings goal name', 'Headphones');
    await field('Goal target', '2000');
    await tester.ensureVisible(find.text('Save budget'));
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(find.text('181'), findsOneWidget); // (9000 - 2500 - 1000 - 50) / 30.
    expect(find.text('1000 / 2000 DZD saved'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect(find.text('181'), findsOneWidget);
    expect(find.text('Headphones'), findsOneWidget);
  });
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
