import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/models/loan.dart';
import '../controllers/budget_book.dart';
import '../design/design.dart';
import '../design/format.dart';
import 'content_widgets.dart';

/// Uses the same cash preview for loan entry and repayment entry.
class LoanBudgetPreview extends StatelessWidget {
  const LoanBudgetPreview(
      {super.key,
      required this.book,
      required this.loan,
      required this.budgetId,
      required this.outsideMessage,
      this.showShortfall = false});
  final BudgetBook book;
  final Loan loan;
  final String? budgetId;
  final String outsideMessage;
  final bool showShortfall;
  @override
  Widget build(BuildContext context) {
    final budget = book.data.budgets.where((b) => b.id == budgetId).firstOrNull;
    if (budget == null) {
      return Text(outsideMessage, style: type(12, color: secondaryText));
    }
    final figures =
        BudgetFigures(budget, DateTime.now(), plans: book.data.plans, loans: [
      for (final existing in book.data.loans)
        if (existing.id != loan.id) existing,
      loan,
    ]);
    return SurfaceCard(
        color: surfaceHigh,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyText('Cash after this transfer: ${figures.cash} DA',
              style: type(13)),
          const SizedBox(height: 8),
          CurrencyText(
              "Today's limit after this transfer: ${figures.todayLimit == null ? 'Outside current period' : '${money(figures.todayLimit!)} DA'}",
              style: type(12, color: secondaryText)),
          if (showShortfall && figures.cash < 0) ...[
            const SizedBox(height: 8),
            Text('This transfer exceeds available cash.',
                style: type(12, color: danger)),
          ],
        ]));
  }
}
