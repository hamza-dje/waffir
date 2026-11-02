import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/presentation/widgets/app_action_button.dart';
import 'package:wafir/presentation/widgets/press_feedback.dart';

void main() {
  Widget view(
          {bool enabled = true, bool reduce = false, bool animate = true}) =>
      MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: Center(
                  child: AppActionButton(
                      animate: animate,
                      onPressed: enabled ? () {} : null,
                      child: const Text('Save')))));
  Finder getScale() => find.descendant(
      of: find.byType(PressFeedback), matching: find.byType(AnimatedScale));

  testWidgets('press scales the full button without changing its layout',
      (tester) async {
    await tester.pumpWidget(view());
    final size = tester.getSize(find.byType(FilledButton));
    final press =
        await tester.startGesture(tester.getCenter(find.text('Save')));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(getScale()).scale, .96);
    expect(tester.getSize(find.byType(FilledButton)), size);
    await press.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(getScale()).scale, 1);
  });

  testWidgets(
      'scroll movement cancels the press; disabled and static stay still',
      (tester) async {
    await tester.pumpWidget(view());
    final press =
        await tester.startGesture(tester.getCenter(find.text('Save')));
    await tester.pump();
    await press.moveBy(const Offset(0, 50));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(getScale()).scale, 1);
    await press.up();
    for (final widget in [view(enabled: false), view(animate: false)]) {
      await tester.pumpWidget(widget);
      final press =
          await tester.startGesture(tester.getCenter(find.text('Save')));
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(getScale()).scale, 1);
      await press.up();
    }
  });

  testWidgets('reduced motion gives opacity feedback with no scale',
      (tester) async {
    await tester.pumpWidget(view(reduce: true));
    final press =
        await tester.startGesture(tester.getCenter(find.text('Save')));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(getScale()).scale, 1);
    expect(
        tester
            .widget<AnimatedOpacity>(find.descendant(
                of: find.byType(PressFeedback),
                matching: find.byType(AnimatedOpacity)))
            .opacity,
        .85);
    await press.up();
    await tester.pumpAndSettle();
  });
}
