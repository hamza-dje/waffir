import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';

Future<void> enterAmount(WidgetTester tester, String amount) async {
  for (final digit in amount.split('')) {
    await tester.tap(find.widgetWithText(TextButton, digit));
    await tester.pump();
  }
}

void main() {
  testWidgets('custom expenses reject invalid input and persist valid input',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'budget_state': jsonEncode({
        'budget': 3000,
        'days': 30,
        'start': DateTime.now().toIso8601String(),
        'expenses': [],
      })
    });
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive whole amount'), findsOneWidget);
    await enterAmount(tester, '120');
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'What was it for?'), 'Books');
    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    expect(find.text('96'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    final store = await SharedPreferences.getInstance();
    final data =
        jsonDecode(store.getString('budget_state')!) as Map<String, dynamic>;
    expect((data['expenses'] as List).single['amount'], 120);
  });
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
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixed costs'));
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
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('181'), findsOneWidget); // (9000 - 2500 - 1000 - 50) / 30.
    expect(find.text('1000 / 2000 DZD'), findsOneWidget);
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
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    final before = await SharedPreferences.getInstance();
    expect(
        (jsonDecode(before.getString('budget_state')!)['expenses'] as List)
            .length,
        1);
    await tester.tap(find.text('Start new period'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await enterAmount(tester, '1400');
    await tester.tap(find.text('Continue'));
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
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await enterAmount(tester, '9000');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('daily-allowance'))).data, '300');
    await tester.tap(find.text('Coffee').first);
    await tester.pumpAndSettle();
    expect(find.text('298'), findsOneWidget);
    expect(find.text('Coffee'), findsNWidgets(2));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('50 DZD spent this period'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect(find.text('298'), findsOneWidget);
    expect(find.text('Coffee'), findsNWidgets(2));
  });
}
