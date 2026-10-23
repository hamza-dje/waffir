import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/design.dart';

void main() {
  test('font role survives size changes', () {
    expect(type(14, role: TextRole.display).fontFamily, 'Geist');
    expect(type(28, role: TextRole.body).fontFamily, 'RedHatDisplay');
  });

  testWidgets('interactive card owns clipped dark feedback and tap behavior',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: TapCard(
                    radius: 16,
                    onTap: () => taps++,
                    child: const SizedBox(
                        width: 200, height: 80, child: Text('Expense')))))));
    final card = find.byType(TapCard);
    final material = tester.widget<Material>(
        find.descendant(of: card, matching: find.byType(Material)).first);
    expect(material.clipBehavior, Clip.antiAlias);
    final ink = tester.widget<InkWell>(
        find.descendant(of: card, matching: find.byType(InkWell)));
    expect(ink.overlayColor!.resolve({WidgetState.pressed}),
        const Color(0x40000000));
    await tester.tap(card);
    expect(taps, 1);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TapCard(child: const Text('Disabled')))));
    await tester.tap(find.text('Disabled'));
    expect(taps, 1);
  });
}
