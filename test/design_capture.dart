// Run with: flutter test test/design_capture.dart
// Uses synthetic data; does not change the installed app's storage.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/main.dart';

void main() {
  testWidgets('capture the six reference states with bundled fonts',
      (tester) async {
    tester.view.physicalSize = const Size(360, 696);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 42, bottom: 20);
    addTearDown(tester.view.reset);
    for (final family in ['Geist', 'GeistMono', 'Rubik']) {
      final loader = FontLoader(family);
      for (final weight in family == 'Geist'
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
        await Directory('build/design').create(recursive: true);
        await File('build/design/$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    }

    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(RepaintBoundary(key: boundary, child: const WafirApp()));
    await capture('period');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    for (final digit in '8000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
    await capture('amount');
    await tester.pumpWidget(const SizedBox());
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'budget_state': jsonEncode({
        'budget': 8500,
        'fixedCosts': 2500,
        'days': 30,
        'start': now.toIso8601String(),
        'saved': 400,
        'goalName': 'Headphones',
        'goalTarget': 1000,
        'pastExpenses': [
          {
            'label': 'Bus',
            'amount': 30,
            'date': now
                .subtract(const Duration(days: 1))
                .copyWith(hour: 7, minute: 55)
                .toIso8601String()
          },
          {
            'label': 'Lunch',
            'amount': 200,
            'date': now
                .subtract(const Duration(days: 1))
                .copyWith(hour: 13, minute: 10)
                .toIso8601String()
          },
        ],
        'expenses': [
          {
            'label': 'Coffee',
            'amount': 50,
            'date':
                DateTime(now.year, now.month, now.day, 8, 12).toIso8601String()
          },
          {
            'label': 'Sandwich',
            'amount': 150,
            'date':
                DateTime(now.year, now.month, now.day, 12, 40).toIso8601String()
          },
        ]
      })
    });
    await tester
        .pumpWidget(RepaintBoundary(key: boundary, child: const WafirApp()));
    await capture('today');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    for (final digit in '120'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
    await capture('expense');
    Navigator.of(tester.element(find.text('Log it'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check'));
    await capture('check');
    await tester.tap(find.text('History'));
    await capture('history');
  });
}
