import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/data/serialization/budget_codec.dart';
import 'package:wafir/presentation/app.dart';
import 'package:wafir/presentation/widgets/app_notice.dart';
import 'budget_book_test.dart' show MemoryBudgetStorage;

void main() {
  testWidgets('new notice replaces the previous one and interrupts exit',
      (tester) async {
    final semantics = tester.ensureSemantics();
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
        builder: (_, child) => AppNoticeHost(child: child!),
        home: Builder(builder: (value) {
          context = value;
          return const Scaffold();
        })));
    AppNoticeHost.show(context, 'Budget started');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('Dismiss message')));
    await tester.pump(const Duration(milliseconds: 50));
    AppNoticeHost.show(context, 'Expense saved');
    await tester.pumpAndSettle();
    expect(find.text('Budget started'), findsNothing);
    expect(find.text('Expense saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Expense saved'), findsNothing);
    semantics.dispose();
  });

  testWidgets('reduced motion fades; accessible navigation keeps messages',
      (tester) async {
    final semantics = tester.ensureSemantics();
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
        builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
                disableAnimations: true, accessibleNavigation: true),
            child: AppNoticeHost(child: child!)),
        home: Builder(builder: (value) {
          context = value;
          return const Scaffold();
        })));
    AppNoticeHost.show(context, 'Budget updated');
    await tester.pump();
    expect(
        tester
            .widget<Transform>(find.byKey(const ValueKey('notice-motion')))
            .transform
            .storage[13],
        0);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Budget updated'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('Dismiss message')));
    await tester.pumpAndSettle();
    expect(find.text('Budget updated'), findsNothing);
    semantics.dispose();
  });

  testWidgets('expense confirmation follows successful storage only',
      (tester) async {
    final now = dayOnly(DateTime.now());
    final storage = MemoryBudgetStorage(BudgetData(budgets: [
      BudgetRecord(
          id: 'b',
          funds: 3000,
          start: now,
          end: DateTime(now.year, now.month, now.day + 29))
    ], products: [
      const UsualProduct('Coffee', 50, 'coffee')
    ]).encode());
    await tester.pumpWidget(WafirApp(storage: storage));
    await tester.pumpAndSettle();
    storage.pending = Completer<bool>();
    await tester.ensureVisible(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee'));
    await tester.pump();
    expect(find.text('Expense saved'), findsNothing);
    storage.pending!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Expense saved'), findsNothing);
    expect(find.byKey(const ValueKey('notice-motion')), findsOneWidget);
    storage.pending = null;
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    expect(find.text('Expense saved'), findsOneWidget);
  });

  testWidgets('capture Budget started above Home', (tester) async {
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
    await tester.pumpWidget(RepaintBoundary(
        key: boundary, child: WafirApp(storage: MemoryBudgetStorage())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    for (final key in '3000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, key));
      await tester.pump();
    }
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start budget'));
    await tester.pumpAndSettle();
    expect(find.text('Budget started'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await Directory('build/ux/notices').create(recursive: true);
      await File('build/ux/notices/budget-started.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
  });
}
