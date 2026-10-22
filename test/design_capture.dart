// Run with: flutter test test/design_capture.dart
// Synthetic data only. Does not change the installed app's storage.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';
import 'package:wafir/budget_data.dart';

void main() {
  testWidgets('capture agreed onboarding and three-tab UX with bundled fonts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 30, bottom: 20);
    addTearDown(tester.view.reset);
    for (final family in ['Geist', 'GeistMono', 'Rubik', 'RedHatDisplay']) {
      final loader = FontLoader(family);
      for (final weight in family == 'RedHatDisplay'
          ? [400, 500, 600]
          : family == 'Geist'
              ? [400, 500, 600, 700]
              : family == 'Rubik'
                  ? [400, 500, 600]
                  : [400, 500]) {
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
        await Directory('build/ux').create(recursive: true);
        await File('build/ux/$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }

    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(RepaintBoundary(key: boundary, child: const WafirApp()));
    await capture('onboarding-dates');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    for (final digit in '3000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
    await capture('onboarding-amount');
    await tester.tap(find.text('Continue'));
    await capture('onboarding-products');
    await tester.pumpWidget(const SizedBox());
    final today = dayOnly(DateTime.now()),
        start = dayOnly(DateTime.now().subtract(const Duration(days: 1)));
    final b = BudgetRecord(
        id: 'active',
        funds: 3000,
        start: start,
        end: DateTime(start.year, start.month, start.day + 29),
        expenses: [
          Expense('Coffee', 50,
              DateTime(start.year, start.month, start.day, 8, 12), 'coffee'),
          Expense('Coffee', 50,
              DateTime(today.year, today.month, today.day, 8, 12), 'coffee')
        ]);
    SharedPreferences.setMockInitialValues({
      'budget_state_v2': BudgetData(budgets: [
        b
      ], products: [
        const UsualProduct('Coffee', 50, 'coffee'),
        const UsualProduct('Bus', 30, 'bus'),
        const UsualProduct('Water', 30, 'droplet')
      ]).encode()
    });
    await tester
        .pumpWidget(RepaintBoundary(key: boundary, child: const WafirApp()));
    await capture('home');
    await tester.ensureVisible(find.text('Add expense'));
    await capture('home-expenses');
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    for (final digit in '120'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
    await capture('expense');
    await tester.tap(find.text('Continue'));
    await capture('expense-details');
    Navigator.of(tester.element(find.text('Log it'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('History').last);
    await capture('history');
    await tester.tap(find.text('Active budget'));
    await capture('history-details');
    await tester.ensureVisible(find.text('Coffee').first);
    await tester.tap(find.text('Coffee').first);
    await capture('edit-expense');
    await tester.ensureVisible(find.text('Delete expense'));
    await tester.tap(find.text('Delete expense'));
    await capture('delete-dialog');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget').last);
    await capture('budget');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit'));
    await capture('edit-budget');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Stop and Save'));
    await tester.tap(find.text('Stop and Save'));
    await capture('stop-save-dialog');
  });
}
