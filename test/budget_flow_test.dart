import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';
import 'package:wafir/budget_data.dart';
import 'package:wafir/design.dart';

Future<void> tap(WidgetTester tester, String text, {bool last = false}) async {
  final finder = last ? find.text(text).last : find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> field(WidgetTester tester, String label, String value) async {
  final finder = find.byKey(ValueKey('input-$label'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> digits(WidgetTester tester, String value) async {
  for (final digit in value.split('')) {
    await tester.tap(find.widgetWithText(TextButton, digit));
    await tester.pump();
  }
}

String figure(WidgetTester tester, String key) {
  final value = tester.widget<CurrencyText>(find.byKey(ValueKey(key))).data;
  return key == 'left-today' ? value.replaceFirst(RegExp(r' DA$'), '') : value;
}

Future<BudgetData> stored() async => BudgetData.decode(
    (await SharedPreferences.getInstance()).getString('budget_state_v2')!);
Future<void> boot(WidgetTester tester, Map<String, Object> values) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(values);
  await tester.pumpWidget(const WafirApp());
  await tester.pumpAndSettle();
}

BudgetRecord seed({int funds = 3000, List<Expense> expenses = const []}) {
  final start = dayOnly(DateTime.now());
  return BudgetRecord(
      id: 'seed',
      funds: funds,
      start: start,
      end: DateTime(start.year, start.month, start.day + 29),
      expenses: expenses);
}

Future<void> pickDate(WidgetTester tester, String label, DateTime value) async {
  await tester.ensureVisible(find.byKey(ValueKey('date-$label')));
  await tester.tap(find.byKey(ValueKey('date-$label')));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Switch to input'));
  await tester.pumpAndSettle();
  await tester.enterText(
      find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextFormField)),
      '${value.month}/${value.day}/${value.year}');
  await tap(tester, 'OK');
}

void main() {
  testWidgets('currency uses the SVG and input borders stay invisible',
      (tester) async {
    await boot(tester, {
      'budget_state_v2': BudgetData(budgets: [seed()]).encode()
    });
    expect(find.byType(CurrencySymbol), findsWidgets);
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Edit');
    final theme = Theme.of(tester.element(find.byType(TextFormField)))
        .inputDecorationTheme;
    for (final border in [
      theme.border,
      theme.enabledBorder,
      theme.focusedBorder,
      theme.errorBorder,
      theme.focusedErrorBorder
    ]) {
      expect(border!.borderSide.style, BorderStyle.none);
    }
  });
  testWidgets('home and editors fit a small screen with larger text',
      (tester) async {
    await boot(tester, {
      'budget_state_v2': BudgetData(
          budgets: [seed()],
          products: [const UsualProduct('Coffee', 50, 'coffee')]).encode()
    });
    tester.view.physicalSize = const Size(360, 696);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Edit');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'onboarding products, fixed daily limit, product snapshots, and corrections survive restart',
      (tester) async {
    await boot(tester, {});
    await tap(tester, 'Continue');
    await digits(tester, '3000');
    await tap(tester, 'Continue');
    await tap(tester, 'Add product');
    await tap(tester, 'Save product');
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a positive whole amount'), findsOneWidget);
    await field(tester, 'Product name', 'Tea');
    await field(tester, 'Usual price', '50');
    await tester.tap(
        find.byWidgetPredicate((w) => w is SourceIcon && w.name == 'coffee'));
    await tester.pump();
    await tap(tester, 'Save product');
    await tap(tester, 'Start budget');
    expect(figure(tester, 'left-today'), '100');
    expect(find.text('Check'), findsNothing);
    expect(find.text('Coffee'), findsNothing);
    await tap(tester, 'Tea');
    expect(figure(tester, 'left-today'), '50');
    expect(figure(tester, 'upcoming-average'), '101.72 DA');
    expect((await stored()).active!.expenses.single.icon, 'coffee');
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Tea');
    await field(tester, 'Usual price', '75');
    await tap(tester, 'Save product');
    expect((await stored()).active!.expenses.single.amount, 50);
    await tap(tester, 'Home', last: true);
    await tap(tester, 'Tea');
    expect(figure(tester, 'left-today'), '-25');
    expect(find.text('Stop for today'), findsOneWidget);
    await tap(tester, 'History', last: true);
    await tap(tester, 'Active budget');
    await tap(tester, 'Tea');
    await field(tester, 'Expense name', 'Tea corrected');
    await field(tester, 'Amount', '30');
    await tester.ensureVisible(find.bySemanticsLabel('bus icon'));
    await tester.tap(find.bySemanticsLabel('bus icon'));
    await tap(tester, 'Save expense');
    expect((await stored()).active!.spent, 80);
    expect((await stored()).active!.expenses.last.icon, 'bus');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'Home', last: true);
    expect(figure(tester, 'left-today'), '20');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect(figure(tester, 'left-today'), '20');
    expect((await stored()).products.single.price, 75);
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Tea');
    await tap(tester, 'Remove product');
    await tap(tester, 'Remove');
    expect((await stored()).products, isEmpty);
    expect((await stored()).active!.spent, 80);
  });
  testWidgets(
      'stop, carry over, correct saved history, and delete without changing transfer',
      (tester) async {
    final old = seed(expenses: [Expense('Old expense', 50, DateTime.now())]);
    await boot(tester, {
      'budget_state_v2': BudgetData(budgets: [old]).encode()
    });
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Stop and Save');
    await tap(tester, 'Stop and save');
    await tap(tester, 'Use remaining money');
    await tap(tester, '7 days');
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    await tap(tester, 'Skip for now');
    var data = await stored();
    expect(data.active!.funds, 2950);
    expect(data.active!.days, 7);
    expect(data.active!.carriedFrom, 'seed');
    expect(data.budgets.first.closedAt, isNotNull);
    await tap(tester, 'History', last: true);
    await tap(tester, 'Saved budget');
    await tap(tester, 'Old expense');
    await field(tester, 'Amount', '100');
    await tap(tester, 'Save expense');
    data = await stored();
    expect(data.budgets.first.balance, 2900);
    expect(data.active!.funds, 2950);
    await tap(tester, 'Old expense');
    await tap(tester, 'Delete expense');
    await tap(tester, 'Cancel');
    expect((await stored()).budgets.first.expenses, hasLength(1));
    await tap(tester, 'Delete expense');
    await tap(tester, 'Delete');
    data = await stored();
    expect(data.budgets.first.expenses, isEmpty);
    expect(data.active!.carriedAmount, 2950);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const WafirApp());
    await tester.pumpAndSettle();
    expect((await stored()).active!.funds, 2950);
  });
  testWidgets(
      'budget and expense dates recalculate history and reject excluded entries',
      (tester) async {
    final now = dayOnly(DateTime.now()),
        yesterday = dayOnly(DateTime.now().subtract(const Duration(days: 1)));
    final b = seed(expenses: [Expense('Past meal', 200, yesterday)]).copyWith(
        start: yesterday,
        end: DateTime(yesterday.year, yesterday.month, yesterday.day + 29));
    await boot(tester, {
      'budget_state_v2': BudgetData(budgets: [b]).encode()
    });
    expect(figure(tester, 'left-today'), '96.55');
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Edit');
    await pickDate(tester, 'Start date', now);
    await tap(tester, 'Save budget');
    expect(
        find.text(
            'These dates exclude an expense. Correct that expense first.'),
        findsOneWidget);
    expect((await stored()).active!.days, 30);
    await pickDate(tester, 'Start date', yesterday);
    await field(tester, 'Total funds', '6000');
    await tap(tester, 'Save budget');
    expect((await stored()).active!.funds, 6000);
    await tap(tester, 'History', last: true);
    await tap(tester, 'Active budget');
    await tap(tester, 'Past meal');
    await pickDate(tester, 'Expense date', now);
    await tap(tester, 'Save expense');
    expect(daysBetween((await stored()).active!.expenses.single.date, now), 0);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'Home', last: true);
    expect(figure(tester, 'left-today'), '6.90'); // 6000/29 - 200.
  });
  testWidgets(
      'legacy funds migrate without reserves or presets and the old data stays intact',
      (tester) async {
    final now = DateTime.now();
    final raw = jsonEncode({
      'budget': 3000,
      'fixedCosts': 500,
      'saved': 200,
      'days': 30,
      'start': now.toIso8601String(),
      'expenses': [Expense('Legacy entry', 50, now).toJson()],
      'pastExpenses': []
    });
    await boot(tester, {'budget_state': raw});
    expect(figure(tester, 'left-today'), '50');
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('USUAL EXPENSES'), findsNothing);
    await tap(tester, 'Add expense');
    await digits(tester, '20');
    await tap(tester, 'Continue');
    expect(find.text('Add a note'), findsNothing);
    await field(tester, 'What was it for?', 'Lunch');
    await tester.ensureVisible(find.bySemanticsLabel('utensils icon'));
    await tester.tap(find.bySemanticsLabel('utensils icon'));
    await tap(tester, 'Log it');
    expect((await stored()).active!.expenses.last.icon, 'utensils');
    expect(figure(tester, 'left-today'), '30');
    expect((await stored()).active!.spent, 70);
    expect(
        (await SharedPreferences.getInstance()).getString('budget_state'), raw);
    await tap(tester, 'Budget', last: true);
    expect(find.text('Fixed costs'), findsNothing);
    expect(find.text('Savings reserved'), findsNothing);
  });
  testWidgets('a final-day overspent budget cannot carry a negative balance',
      (tester) async {
    final now = dayOnly(DateTime.now());
    final b = seed(funds: 100, expenses: [Expense('Food', 150, now)])
        .copyWith(end: now);
    await boot(tester, {
      'budget_state_v2': BudgetData(budgets: [b]).encode()
    });
    expect(figure(tester, 'left-today'), '-50');
    expect(figure(tester, 'upcoming-average'), 'No days remaining');
    await tap(tester, 'Budget', last: true);
    await tap(tester, 'Stop and Save');
    await tap(tester, 'Stop and save');
    expect(find.text('Use remaining money'), findsNothing);
    expect(find.text('Choose your\nbudget dates'), findsOneWidget);
    await tap(tester, 'Cancel');
    expect((await stored()).active, isNull);
  });
  testWidgets('history search filters names and keeps the correct edit index',
      (tester) async {
    await boot(tester, {
      'budget_state_v2': BudgetData(budgets: [
        seed(expenses: [
          Expense('Coffee', 50, DateTime.now()),
          Expense('Bus fare', 30, DateTime.now())
        ])
      ]).encode()
    });
    await tap(tester, 'History', last: true);
    await tap(tester, 'Active budget');
    final search = find.byType(TextField).first;
    await tester.ensureVisible(search);
    await tester.enterText(search, 'BUS');
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('Bus fare'), findsOneWidget);
    await tap(tester, 'Bus fare');
    await field(tester, 'Amount', '40');
    await tap(tester, 'Save expense');
    expect((await stored()).active!.expenses.last.amount, 40);
    expect((await stored()).active!.expenses.first.amount, 50);
  });
  testWidgets('invalid stored data shows an error without replacing it',
      (tester) async {
    await boot(tester, {'budget_state_v2': 'bad json'});
    expect(find.textContaining('Could not load your budget'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('budget_state_v2'),
        'bad json');
  });
}
