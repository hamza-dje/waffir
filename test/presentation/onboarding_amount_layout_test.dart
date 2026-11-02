import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/presentation/app.dart';
import 'package:wafir/presentation/widgets/form_controls.dart';
import 'budget_book_test.dart' show MemoryBudgetStorage;

void main() {
  testWidgets('long expressions keep keypad and Continue in place',
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
    await tester.pumpWidget(RepaintBoundary(
        key: boundary, child: WafirApp(storage: MemoryBudgetStorage(null))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final keypad = tester.getRect(find.byType(AmountKeypad));
    final button =
        tester.getRect(find.widgetWithText(FilledButton, 'Continue'));
    for (final key in '110+2000+5000'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, key));
      await tester.pump();
      expect(tester.getRect(find.byType(AmountKeypad)), keypad);
      expect(tester.getRect(find.widgetWithText(FilledButton, 'Continue')),
          button);
      expect(tester.takeException(), isNull);
    }
    expect(button.bottom, lessThanOrEqualTo(824));
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      await Directory('build/ux/fixes').create(recursive: true);
      await File('build/ux/fixes/onboarding-long-amount.png')
          .writeAsBytes(bytes.buffer.asUint8List());
      image.dispose();
    });
  });
}
