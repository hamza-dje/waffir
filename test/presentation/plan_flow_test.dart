import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/data/serialization/budget_codec.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/domain/models/spending_plan.dart';
import 'package:wafir/presentation/app.dart';
import 'package:wafir/presentation/widgets/content_widgets.dart';
import 'package:wafir/presentation/widgets/form_controls.dart';
import 'budget_book_test.dart' show MemoryBudgetStorage;

void main() {
  testWidgets('Custom mode saves and reopens separate daily estimates',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final today = dayOnly(DateTime.now());
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final storage = MemoryBudgetStorage(BudgetData(budgets: [
      BudgetRecord(
          id: 'b',
          funds: 3000,
          start: today,
          end: DateTime(today.year, today.month, today.day + 29))
    ]).encode());
    await tester.pumpWidget(WafirApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('input-Plan label')), 'Study days');
    tester.testTextInput.hide();
    for (final entry in [(today, '50'), (tomorrow, '120+30')]) {
      await tester.ensureVisible(find.text('Add day'));
      await tester.tap(find.text('Add day'));
      await tester.pumpAndSettle();
      if (entry.$1.month != today.month) {
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('${entry.$1.day}').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('input-Amount')), entry.$2);
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
    }
    for (final field in find.byType(PickerButton).evaluate()) {
      expect(tester.getSize(find.byWidget(field.widget)).height, 54);
    }
    for (final button in find.byType(AppActionIcon).evaluate()) {
      expect(tester.getSize(find.byWidget(button.widget)).height, 54);
    }
    final amountButtons = find.descendant(
        of: find.byType(PickerButton), matching: find.byType(TextButton));
    expect(amountButtons, findsNothing);
    expect(find.byType(PickerButton), findsNWidgets(4));
    await tester.tap(
        find.byWidgetPredicate((w) => w is PickerButton && w.text == '50 DA'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('input-Amount')), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    await tester.tap(find
        .byWidgetPredicate((w) => w is PickerButton && w.icon == 'calendar')
        .first);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save plan'));
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    final saved = BudgetCodec.decode(storage.value!).plans.single;
    expect(saved.mode, PlanAmountMode.custom);
    expect(saved.days.map((d) => d.amount), [50, 150]);
    expect(saved.reserved, 200);
    await tester.tap(find.text('Study days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save plan'));
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(
        BudgetCodec.decode(storage.value!)
            .plans
            .single
            .days
            .map((d) => d.amount),
        [50, 150]);
  });

  testWidgets('Plan creation, recording, linked corrections and screenshots',
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
        await Directory('build/ux/plan').create(recursive: true);
        await File('build/ux/plan/$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }

    final today = dayOnly(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final storage = MemoryBudgetStorage(BudgetData(budgets: [
      BudgetRecord(
          id: 'b',
          funds: 3000,
          start: yesterday,
          end: DateTime(today.year, today.month, today.day + 28))
    ], plans: [
      SpendingPlan(
          id: 'missed',
          budgetId: 'b',
          label: 'Library fees',
          icon: 'calendar',
          days: [PlanDay(id: 'late', date: yesterday, amount: 50)]),
      SpendingPlan(
          id: 'seed',
          budgetId: 'b',
          label: 'Bus pass',
          icon: 'bus',
          days: SpendingPlan.split(
              [tomorrow, DateTime(today.year, today.month, today.day + 3)],
              100,
              true,
              'bus'))
    ]).encode());
    await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: WafirApp(storage: storage)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next plan'));
    await capture('home');
    await tester.tap(find.text('Plan').last);
    await tester.pumpAndSettle();
    await capture('overview');
    await tester.tap(find.text('Add plan'));
    await tester.pumpAndSettle();
    for (final key in ['1', '2', '0', '+', '2', '5', '0']) {
      await tester.tap(find.widgetWithText(TextButton, key));
      await tester.pump();
    }
    await capture('amount');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('input-Plan label')),
        'Lunch with classmates');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Add day'));
    await tester.tap(find.text('Add day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save plan'));
    await capture('details-form');
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(BudgetCodec.decode(storage.value!).plans.last.reserved, 370);
    await tester.ensureVisible(find.text('Lunch with classmates'));
    await tester.tap(find.text('Lunch with classmates'));
    await tester.pumpAndSettle();
    await capture('details');
    await tester.ensureVisible(find.text('Record expense'));
    await tester.tap(find.text('Record expense'));
    await tester.pumpAndSettle();
    expect(find.text('Delete expense'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('input-Amount')), '350');
    await tester.ensureVisible(find.text('Log it'));
    await tester.tap(find.text('Log it'));
    await tester.pumpAndSettle();
    expect(BudgetCodec.decode(storage.value!).plans.last.reserved, 0);
    expect(
        BudgetCodec.decode(storage.value!).active!.expenses.single.amount, 350);
    await capture('recorded');
    await tester.ensureVisible(find.text('Edit expense'));
    await tester.tap(find.text('Edit expense'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete expense'));
    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(BudgetCodec.decode(storage.value!).plans.last.reserved, 370);
    expect(BudgetCodec.decode(storage.value!).active!.expenses, isEmpty);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final search = find.descendant(
        of: find.byType(SearchInput), matching: find.byType(TextField));
    await tester.enterText(search, 'no such plan');
    await tester.pumpAndSettle();
    expect(find.text('Bus pass'), findsNothing);
    await tester.enterText(search, '');
    tester.testTextInput.hide();
    await tester.tap(find.text('Needs review'));
    await tester.pumpAndSettle();
    expect(find.text('Library fees'), findsOneWidget);
    expect(find.text('Bus pass'), findsNothing);
    await capture('needs-review');
  });
}
