import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/presentation/widgets/content_transition.dart';

void main() {
  Widget view(int step, {bool reduce = false, String label = 'Amount'}) =>
      MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: ContentTransition(
                  change: step,
                  child:
                      SizedBox(width: 200, height: 100, child: Text(label)))));

  double opacity(WidgetTester tester) => tester
      .widget<FadeTransition>(find.descendant(
          of: find.byType(ContentTransition),
          matching: find.byType(FadeTransition)))
      .opacity
      .value;

  testWidgets('step fade keeps layout stable and does not replay on typing',
      (tester) async {
    await tester.pumpWidget(view(0));
    expect(opacity(tester), 1);
    final bounds = tester.getRect(find.byType(ContentTransition));
    await tester.pumpWidget(view(1));
    expect(opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 80));
    final current = opacity(tester);
    expect(current, inExclusiveRange(0, 1));
    await tester.pumpWidget(view(1, label: '120 + 50'));
    expect(opacity(tester), current);
    expect(tester.getRect(find.byType(ContentTransition)), bounds);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('rapid step changes continue the fade without duplicate views',
      (tester) async {
    await tester.pumpWidget(view(0));
    await tester.pumpWidget(view(1));
    await tester.pump(const Duration(milliseconds: 60));
    final current = opacity(tester);
    await tester.pumpWidget(view(2, label: 'New step'));
    expect(opacity(tester), current);
    expect(find.text('Amount'), findsNothing);
    expect(find.text('New step'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets('reduced motion uses a short, gentle fade', (tester) async {
    await tester.pumpWidget(view(0, reduce: true));
    await tester.pumpWidget(view(1, reduce: true));
    expect(opacity(tester), .97);
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(tester), 1);
    expect(
        find.descendant(
            of: find.byType(ContentTransition),
            matching: find.byType(SlideTransition)),
        findsNothing);
  });
}
