import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/data/serialization/budget_codec.dart';
import 'package:wafir/domain/models/app_currency.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/domain/models/loan.dart';
import 'package:wafir/domain/rules/amount_expression.dart';
import 'package:wafir/presentation/app.dart';
import 'package:wafir/presentation/controllers/budget_book.dart';
import 'budget_book_test.dart' show MemoryBudgetStorage;

void main() {
  test('currency parsing and storage keep units and currencies separate',
      () async {
    expect(moneyValue('12.50', currency: AppCurrency.eur), 1250);
    expect(moneyValue('12.50+0.25', currency: AppCurrency.eur), 1275);
    expect(moneyValue('0.001', currency: AppCurrency.eur), isNull);
    expect(moneyValue('12.50'), isNull);
    final today = dayOnly(DateTime.now());
    final old = BudgetRecord(
        id: 'old', funds: 3000, start: today, end: today, closedAt: today);
    final storage = MemoryBudgetStorage(BudgetData(budgets: [old]).encode());
    final book = BudgetBook(storage);
    expect(await book.load(), isTrue);
    expect(await book.setCurrency(AppCurrency.eur), isTrue);
    expect(
        await book.startBudget(10000, today,
            DateTime(today.year, today.month, today.day + 29), []),
        isTrue);
    expect(book.data.active!.currency, AppCurrency.eur);
    expect(book.data.budgets.first.currency, AppCurrency.dzd);
    expect(book.data.budgets.first.funds, 3000);
    final saved = BudgetCodec.decode(storage.value!);
    expect(saved.defaultCurrency, AppCurrency.eur);
    expect(saved.active!.funds, 10000);
    final foreignLoan = Loan(
        id: 'e',
        person: 'Example',
        amount: 100,
        lent: true,
        date: today,
        currency: AppCurrency.eur,
        budgetId: 'old');
    expect(await book.saveLoan(foreignLoan), isFalse);
    expect(book.error, 'Choose a budget in the same currency.');
    expect(book.data.loans, isEmpty);
    book.dispose();
  });

  testWidgets('Settings, four tabs, budget routes and euro cents screenshots',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 30, bottom: 20);
    addTearDown(tester.view.reset);
    for (final family in ['Geist', 'RedHatDisplay']) {
      final loader = FontLoader(family);
      for (final weight in [400, 500, 600, 700]) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await Directory('build/ux/currency').create(recursive: true);
        await File('build/ux/currency/$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }

    final today = dayOnly(DateTime.now());
    final storage = MemoryBudgetStorage(BudgetData(budgets: [
      BudgetRecord(
          id: 'old', funds: 3000, start: today, end: today, closedAt: today),
      BudgetRecord(
          id: 'euro',
          currency: AppCurrency.eur,
          funds: 10000,
          start: today,
          end: DateTime(today.year, today.month, today.day + 29)),
    ]).encode());
    await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: WafirApp(storage: storage)));
    await tester.pumpAndSettle();
    await capture('home-euro');
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Euro - EUR'));
    await tester.pumpAndSettle();
    expect(BudgetCodec.decode(storage.value!).defaultCurrency, AppCurrency.eur);
    expect(BudgetCodec.decode(storage.value!).budgets.first.funds, 3000);
    await capture('settings');
    await tester.tap(find.text('Budget').last);
    await tester.pumpAndSettle();
    await capture('budget');
    await tester.tap(find.text('Loans'));
    await tester.pumpAndSettle();
    expect(find.text('Add loan'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Add plan'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add expense'));
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    for (final digit in ['1', '2', '.', '5', '0']) {
      await tester.ensureVisible(find.widgetWithText(TextButton, digit));
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
    await capture('expense-euro');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('input-What was it for?')), 'Lunch');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Log it'));
    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    expect(BudgetCodec.decode(storage.value!).active!.expenses.single.amount,
        1250);
  });
}
