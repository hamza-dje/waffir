import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';
import 'package:wafir/price_check.dart';

void main() {
  testWidgets(
      'search, quote, alternatives and expense comparison work together',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'budget_state': jsonEncode({
        'budget': 5400,
        'days': 30,
        'start': DateTime.now().toIso8601String(),
        'expenses': [],
      })
    });
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Search purchases'), 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('No matching purchase. Try chicken, eggs or lentils.'),
        findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Search purchases'), 'chicken');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chicken · 1 kg'));
    await tester.pumpAndSettle();
    expect(find.text('That is 3.5 days of your allowance.'), findsOneWidget);
    expect(find.text('Oran · Reference date: 20 Oct 2026 · Not live'),
        findsOneWidget);
    expect(find.text('Eggs · 12 pcs'), findsOneWidget);
    final quoted =
        find.widgetWithText(TextField, 'Your quoted price (optional)');
    await tester.ensureVisible(quoted);
    await tester.enterText(quoted, '90');
    await tester.pumpAndSettle();
    expect(find.text('That is 0.5 days of your allowance.'), findsOneWidget);
    await tester.enterText(quoted, '0');
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive whole amount.'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Meal\n300 DZD'));
    await tester.tap(find.text('Meal\n300 DZD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chicken · 1 kg'));
    await tester.pumpAndSettle();
    expect(find.text('That is 3.7 days of your allowance.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eggs · 12 pcs').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eggs · 12 pcs').last);
    await tester.pumpAndSettle();
    expect(find.text('That is 1.9 days of your allowance.'), findsOneWidget);
  });

  for (final allowance in [0, -10]) {
    testWidgets('price checks handle allowance $allowance', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: PriceCheck(allowance: allowance, expired: false)))));
      await tester.tap(find.text('Chicken · 1 kg'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'No daily allowance is available. Review your budget before this purchase.'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('price-days')), findsNothing);
    });
  }
}
