import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../design/design.dart';
import '../design/format.dart';

class ExpenseRows extends StatelessWidget {
  const ExpenseRows(
      {super.key,
      required this.budget,
      required this.onEdit,
      this.onlyToday = false,
      this.query = ''});
  final BudgetRecord budget;
  final ValueChanged<int> onEdit;
  final bool onlyToday;
  final String query;
  @override
  Widget build(BuildContext context) {
    final indexed = budget.expenses
        .asMap()
        .entries
        .where((e) =>
            (!onlyToday || daysBetween(e.value.date, DateTime.now()) == 0) &&
            e.value.label.toLowerCase().contains(query.trim().toLowerCase()))
        .toList()
      ..sort((a, b) => b.value.date.compareTo(a.value.date));
    final groups = <DateTime, List<MapEntry<int, Expense>>>{};
    for (final e in indexed) {
      groups.putIfAbsent(dayOnly(e.value.date), () => []).add(e);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (indexed.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            child: CurrencyText(
                query.trim().isEmpty
                    ? 'No expenses yet.'
                    : 'No matching expenses.',
                style: type(13, color: secondaryText))),
      for (final group in groups.entries) ...[
        if (!onlyToday)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(children: [
                Expanded(child: sectionLabel(dateText(group.key))),
                CurrencyText(
                    '${group.value.fold<int>(0, (sum, e) => sum + e.value.amount)} DA',
                    style: type(11))
              ])),
        for (final entry in group.value)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TapCard(
                  radius: 16,
                  onTap: () => onEdit(entry.key),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      child: Row(children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: panel(radius: 12),
                            child: Center(
                                child: SourceIcon(entry.value.icon,
                                    size: 18, color: secondaryText))),
                        const SizedBox(width: listItemGap),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              CurrencyText(entry.value.label,
                                  style: type(13, weight: FontWeight.w500)),
                              const SizedBox(height: 1),
                              CurrencyText(
                                  '${entry.value.date.hour.toString().padLeft(2, '0')}:${entry.value.date.minute.toString().padLeft(2, '0')} · tap to edit',
                                  style: type(11, color: tertiaryText))
                            ])),
                        CurrencyText('−${entry.value.amount} DA',
                            style: type(13, weight: FontWeight.w600))
                      ])))),
      ],
    ]);
  }
}
