import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../design/design.dart';
import '../design/format.dart';
import 'content_widgets.dart';

class PlanHomeSummary extends StatelessWidget {
  const PlanHomeSummary(
      {super.key,
      required this.data,
      required this.budgetId,
      required this.onOpen});
  final BudgetData data;
  final String budgetId;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final plans = data.plans.where((p) => p.budgetId == budgetId);
    final entries = [
      for (final p in plans)
        for (final d in p.days.where((d) => d.pending)) (p, d)
    ]..sort((a, b) => a.$2.date.compareTo(b.$2.date));
    if (entries.isEmpty) return const SizedBox.shrink();
    final next = entries
            .where((e) => daysBetween(DateTime.now(), e.$2.date) >= 0)
            .firstOrNull ??
        entries.first;
    final review = daysBetween(next.$2.date, DateTime.now()) > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SurfaceCard(
          child: Row(children: [
        const SourceIcon('banknote', color: caution),
        const SizedBox(width: listItemGap),
        Expanded(
            child: Text('Planned spending',
                style: type(13, color: secondaryText))),
        CurrencyText('${plans.fold<int>(0, (s, p) => s + p.reserved)} DA',
            style: type(22,
                role: TextRole.display,
                color: caution,
                weight: FontWeight.w600)),
      ])),
      const SizedBox(height: spaceRelated),
      TapCard(
          onTap: onOpen,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(review ? 'Needs review' : 'Next plan',
                              style: type(12,
                                  color: review ? caution : secondaryText))),
                      const SourceIcon('chevron-right',
                          size: 16, color: tertiaryText),
                    ]),
                    const SizedBox(height: spaceRelated),
                    Row(children: [
                      SourceIcon(next.$1.icon, color: mint),
                      const SizedBox(width: listItemGap),
                      Expanded(
                          child: Text(next.$1.label,
                              style: type(16, weight: FontWeight.w600))),
                      const SizedBox(width: spaceTight),
                      CurrencyText('${next.$2.amount} DA',
                          style:
                              type(20, color: mint, weight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: spaceRelated),
                    Row(children: [
                      const SourceIcon('calendar',
                          size: 16, color: secondaryText),
                      const SizedBox(width: listItemGap),
                      Text(dateText(next.$2.date),
                          style: type(12, color: secondaryText)),
                    ]),
                  ]))),
      const SizedBox(height: spaceTight),
      Text('Reserved money is separate from ordinary spending.',
          style: type(11, color: secondaryText)),
      const SizedBox(height: spaceSection),
    ]);
  }
}
