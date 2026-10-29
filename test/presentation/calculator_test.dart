import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wafir/domain/models/budget_data.dart';
import 'package:wafir/presentation/design/design.dart';
import 'package:wafir/presentation/screens/editors.dart';
import 'package:wafir/presentation/widgets/expense_sheet.dart';

void main() {
  testWidgets('typed calculation saves a product with the calculated price',
      (tester) async {
    Object? saved;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return TextButton(
          onPressed: () async {
            saved = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProductEditor()));
          },
          child: const Text('Open'));
    })));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('input-Product name')), 'Food');
    await tester.enterText(
        find.byKey(const ValueKey('input-Usual price')), '120+250');
    await tester.ensureVisible(find.text('Save product'));
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();
    expect((saved as UsualProduct).price, 370);
  });

  testWidgets('expense keypad calculates before continuing', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ExpenseSheet(
                budget: BudgetRecord(
                    id: 'b',
                    funds: 3000,
                    start: dayOnly(now),
                    end: dayOnly(now))))));
    for (final key in ['3', '4', '0', '÷', '5', '=']) {
      await tester.tap(find.widgetWithText(TextButton, key));
      await tester.pump();
    }
    expect(
        find.byWidgetPredicate((w) => w is CurrencyText && w.data == '68 DA'),
        findsOneWidget);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Log it'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
