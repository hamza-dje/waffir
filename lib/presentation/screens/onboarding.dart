import '../widgets/product_list.dart';
import '../widgets/editor_actions.dart';
import '../widgets/form_controls.dart';
import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/rules/expense_rules.dart';
import '../design/design.dart';
import 'editors.dart';

class BudgetOnboarding extends StatefulWidget {
  const BudgetOnboarding(
      {super.key,
      required this.onSave,
      this.onCancel,
      this.initialFunds,
      this.products = const []});
  final Future<bool> Function(
          int funds, DateTime start, DateTime end, List<UsualProduct> products)
      onSave;
  final VoidCallback? onCancel;
  final int? initialFunds;
  final List<UsualProduct> products;
  @override
  State<BudgetOnboarding> createState() => _BudgetOnboardingState();
}

class _BudgetOnboardingState extends State<BudgetOnboarding> {
  int step = 0;
  DateTime start = dayOnly(DateTime.now());
  late DateTime end = DateTime(start.year, start.month, start.day + 29);
  late String amount = widget.initialFunds == null
      ? ''
      : MoneyScope.read(context).input(widget.initialFunds!);
  late List<UsualProduct> products = [...widget.products];
  bool busy = false;
  String? error;
  Future<void> next() async {
    if (step == 0) {
      final days = daysBetween(start, end) + 1;
      if (days < 1 || days > 3660) {
        setState(() => error = 'Choose between 1 and 3660 budget days.');
        return;
      }
    } else if (step == 1) {
      final invalid = positiveMoney(amount, currency: MoneyScope.read(context));
      if (invalid != null) {
        setState(() => error = invalid);
        return;
      }
      amount = MoneyScope.read(context)
          .input(moneyValue(amount, currency: MoneyScope.read(context))!);
    }
    if (step < 2) {
      setState(() {
        step++;
        error = null;
      });
      return;
    }
    setState(() => busy = true);
    final ok = await widget.onSave(
        moneyValue(amount, currency: MoneyScope.read(context))!,
        start,
        end,
        products);
    if (mounted && !ok) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) setState(() => step--);
      },
      child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              pageInset, 6, pageInset, spaceSection),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                    height: compactActionHeight,
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                for (var i = 0; i < 3; i++)
                                                  Container(
                                                      width: 24,
                                                      height: 4,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 6),
                                                      decoration: panel(
                                                          radius: 2,
                                                          color: i <= step
                                                              ? mint
                                                              : surfaceHigh))
                                              ]),
                                        ])),
                                const SizedBox(height: spaceSection),
                                PageHeading(
                                    backAbove: step == 1,
                                    title: [
                                      'Choose your budget dates',
                                      'How much do you have?',
                                      'Your usual products'
                                    ][step],
                                    leading: step == 0
                                        ? null
                                        : AppBackButton(
                                            onPressed: busy
                                                ? null
                                                : () => setState(() {
                                                      step--;
                                                      error = null;
                                                    })),
                                    style: type(26,
                                        role: TextRole.display,
                                        weight: FontWeight.w600,
                                        spacing: -.65,
                                        height: 1.15)),
                                const SizedBox(height: 8),
                                CurrencyText(
                                    [
                                      'Choose the first and last day. Both days count.',
                                      'Your full budget. You can correct it later.',
                                      'Add what you usually spend on, with its usual price. You can change this later.'
                                    ][step],
                                    style: type(13,
                                        color: secondaryText, height: 1.5)),
                                const SizedBox(height: 24),
                                if (step == 0) ...[
                                  DateControl(
                                      'Start date',
                                      start,
                                      (d) => setState(() {
                                            start = d;
                                            if (end.isBefore(start)) {
                                              end = start;
                                            }
                                          })),
                                  DateControl('End date', end,
                                      (d) => setState(() => end = d)),
                                  CurrencyText(
                                      '${daysBetween(start, end) + 1} days',
                                      style: type(13, color: secondaryText)),
                                  const SizedBox(height: 12),
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    for (final days in [7, 15, 21, 28])
                                      OutlinedButton(
                                          style: compactAction(cancel: true)
                                              .copyWith(
                                                  backgroundColor:
                                                      const WidgetStatePropertyAll(
                                                          surface)),
                                          onPressed: () => setState(() => end =
                                              DateTime(start.year, start.month,
                                                  start.day + days - 1)),
                                          child: CurrencyText('$days days'))
                                  ]),
                                ] else if (step == 1) ...[
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: spaceRelated),
                                      child: Semantics(
                                          label:
                                              'Total funds in ${MoneyScope.of(context).code}',
                                          value: amount.isEmpty ? '0' : amount,
                                          child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: CurrencyText(
                                                  '${amount.isEmpty ? '0' : amount} DA',
                                                  input: true,
                                                  style: type(64,
                                                      role: TextRole.display,
                                                      weight: FontWeight.w600,
                                                      spacing: -2.56,
                                                      height: 1))))),
                                  const SizedBox(height: spaceRelated),
                                  const Spacer(),
                                  AmountKeypad(
                                      keyHeight: 52,
                                      onKey: (key) => setState(() {
                                            error = null;
                                            amount = amountKey(amount, key,
                                                currency:
                                                    MoneyScope.read(context));
                                          })),
                                ] else
                                  ProductList(
                                      showEmptyHint: false,
                                      onEdit: (product) =>
                                          editProduct(context, product),
                                      products: products,
                                      enabled: !busy,
                                      onChanged: (items) =>
                                          setState(() => products = items)),
                                if (step != 1) const Spacer(),
                                if (error != null)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: CurrencyText(error!,
                                          style: type(13, color: caution))),
                                const SizedBox(height: 12),
                                FilledButton(
                                    onPressed: busy ? null : next,
                                    child: CurrencyText(busy
                                        ? 'Saving…'
                                        : step == 2
                                            ? 'Start budget'
                                            : 'Continue')),
                                if (step == 0 && widget.onCancel != null) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                      onPressed: busy ? null : widget.onCancel,
                                      child: const CurrencyText('Skip')),
                                ],
                                if (step == 2 && products.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                      onPressed: busy ? null : next,
                                      child:
                                          const CurrencyText('Skip for now')),
                                ],
                              ])))))));
}
