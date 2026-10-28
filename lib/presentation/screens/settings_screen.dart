import 'package:flutter/material.dart';
import '../controllers/budget_book.dart';
import '../design/design.dart';
import '../widgets/content_widgets.dart';
import '../widgets/editor_actions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.book});
  final BudgetBook book;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeading(title: 'Settings'),
        const SizedBox(height: spaceSection),
        SurfaceCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text('Currency for new budgets',
                  style: type(16, weight: FontWeight.w600)),
              const SizedBox(height: spaceRelated),
              Text(
                  'Existing budgets keep their currency. Amounts are not converted.',
                  style: type(13, color: secondaryText, height: 1.5)),
              const SizedBox(height: spaceRelated),
              for (final value in AppCurrency.values)
                Padding(
                    padding: const EdgeInsets.only(bottom: spaceTight),
                    child: FilledButton(
                        onPressed: book.saving
                            ? null
                            : () async {
                                final ok = await book.setCurrency(value);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(book.error ??
                                              'Could not save.')));
                                }
                              },
                        style: compactAction(
                            cancel: book.data.defaultCurrency != value),
                        child: Row(children: [
                          CurrencySymbol(
                              currency: value,
                              size: 12,
                              color: book.data.defaultCurrency == value
                                  ? ink
                                  : primaryText),
                          const SizedBox(width: listItemGap),
                          Expanded(
                              child: Text(value == AppCurrency.dzd
                                  ? 'Algerian dinar'
                                  : 'Euro')),
                          if (book.data.defaultCurrency == value)
                            const SourceIcon('check', color: ink)
                        ])))
            ])),
      ]);
}
