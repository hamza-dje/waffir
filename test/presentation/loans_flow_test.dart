import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/domain/models/loan.dart';
import 'package:wafir/presentation/app.dart';
import 'budget_book_test.dart' show MemoryBudgetStorage;
import 'package:wafir/data/serialization/budget_codec.dart';

void main() {
  testWidgets('loans UI, search, partial repayment, edits, and screenshots',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 30, bottom: 20);
    addTearDown(tester.view.reset);
    for (final family in ['Geist', 'RedHatDisplay']) {
      final loader = FontLoader(family);
      for (final w
          in family == 'Geist' ? [400, 500, 600, 700] : [400, 500, 600]) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$w.ttf'));
      }
      await loader.load();
    }
    final now = DateTime.now();
    final today = dayOnly(now);
    final start = DateTime(today.year, today.month, today.day - 5);
    final storage = MemoryBudgetStorage(BudgetData(budgets: [
      BudgetRecord(
          id: 'b',
          funds: 6000,
          start: start,
          end: DateTime(start.year, start.month, start.day + 29),
          expenses: [Expense('Coffee', 50, start, 'coffee')])
    ], loans: [
      Loan(
          id: 'amine',
          person: 'Amine',
          amount: 500,
          lent: true,
          date: start,
          due: DateTime(today.year, today.month, today.day + 3),
          budgetId: 'b',
          note: 'Books for this semester',
          payments: [
            LoanPayment(
                id: 'p',
                amount: 100,
                date: DateTime(today.year, today.month, today.day - 1),
                budgetId: 'b')
          ]),
      Loan(
          id: 'sara',
          person: 'Sara',
          amount: 1000,
          lent: false,
          date: start,
          due: today,
          budgetId: 'b'),
      Loan(
          id: 'yasmine',
          person: 'Yasmine',
          amount: 300,
          lent: true,
          date: start,
          due: DateTime(today.year, today.month, today.day - 2),
          budgetId: 'b'),
    ]).encode());
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/ux/loans').create(recursive: true);
        await File('build/ux/loans/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: WafirApp(storage: storage)));
    await tester.pumpAndSettle();
    await capture('home');
    await tester.tap(find.text('Loans').last);
    await capture('overview');
    await tester.tap(find.text('Amine'));
    await capture('details');
    await tester.tap(find.text('Record repayment'));
    await capture('repayment');
    final payment = find.byKey(const ValueKey('input-Payment amount'));
    await tester.enterText(payment, '200');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save payment'));
    await tester.tap(find.text('Save payment'));
    await tester.pumpAndSettle();
    expect(find.text('Record repayment'), findsOneWidget);
    expect(
        BudgetCodec.decode(storage.value!)
            .loans
            .firstWhere((l) => l.id == 'amine')
            .remaining,
        200);
    await tester.tap(find.text('Edit'));
    await capture('edit-loan');
    await tester.ensureVisible(find.text('Delete loan'));
    await tester.tap(find.text('Delete loan'));
    await tester.pumpAndSettle();
    expect(find.text('Delete the payment records first.'), findsOneWidget);
    Navigator.of(tester.element(find.text('Save loan'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add loan'));
    await capture('add-amount');
    for (final digit in '250'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
    await tester.tap(find.text('Continue'));
    await capture('add-details');
    final person = find.widgetWithText(TextField, 'e.g. Amine');
    await tester.enterText(person, 'Nadir');
    await tester.ensureVisible(find.text('Save loan'));
    await capture('add-budget-preview');
    await tester.tap(find.text('Save loan'));
    await tester.pumpAndSettle();
    expect(
        BudgetCodec.decode(storage.value!)
            .loans
            .any((l) => l.person == 'Nadir'),
        true);
    final search = find.widgetWithText(TextField, 'Search people or notes');
    await tester.enterText(search, 'Nadir');
    await tester.pumpAndSettle();
    expect(
        find
            .text('Nadir', skipOffstage: true)
            .evaluate()
            .where((e) => e.widget is Text)
            .length,
        1);
    expect(find.text('Sara'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: WafirApp(storage: storage)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loans').last);
    await tester.pumpAndSettle();
    expect(
        find
            .text('Nadir', skipOffstage: true)
            .evaluate()
            .where((e) => e.widget is Text)
            .length,
        1);
  });
}
