import 'package:flutter/material.dart';
import '../design/design.dart';
import 'form_controls.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/rules/expense_rules.dart';

class ExpenseSheet extends StatefulWidget {
  const ExpenseSheet({super.key, required this.budget});
  final BudgetRecord budget;
  @override
  State<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<ExpenseSheet> {
  final name = TextEditingController();
  String amount = '';
  String? error;
  bool details = false;
  String icon = 'banknote';
  TimeOfDay time = TimeOfDay.now();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 32 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration:
                            panel(radius: 2, color: const Color(0x995B6472)))),
                const SizedBox(height: 20),
                CurrencyText('Log an expense',
                    style: type(20,
                        role: TextRole.display, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                      child: CurrencyText(
                          'Today · ${DateTime.now().day}/${DateTime.now().month}',
                          style: type(11, color: tertiaryText))),
                ]),
                const SizedBox(height: 8),
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CurrencyText(
                            '${amount.isEmpty ? '0' : amount} DA',
                            style: type(52,
                                role: TextRole.display,
                                weight: FontWeight.w600,
                                spacing: -2),
                            textAlign: TextAlign.center))),
                if (!details)
                  AmountKeypad(
                      keyHeight: 52,
                      onKey: (key) => setState(() {
                            error = null;
                            amount = amountKey(amount, key);
                          })),
                if (details)
                  LabeledField(
                      label: 'What was it for?',
                      controller: name,
                      maxLength: 60),
                if (details) ...[
                  ExpenseIcons(icon, (value) => setState(() => icon = value)),
                  const SizedBox(height: 16),
                  ExpenseTime(time, (value) => setState(() => time = value)),
                ],
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CurrencyText(error!,
                          style: type(13, color: caution))),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: () {
                      final value = moneyValue(amount);
                      final invalidAmount = positiveMoney(amount);
                      if (invalidAmount != null) {
                        setState(() => error = invalidAmount);
                        return;
                      }
                      if (!details) {
                        setState(() {
                          amount = value.toString();
                          details = true;
                        });
                        return;
                      }
                      final now = DateTime.now();
                      final date = DateTime(
                          now.year, now.month, now.day, time.hour, time.minute);
                      final expense =
                          Expense(name.text.trim(), value!, date, icon);
                      final invalid =
                          ExpenseRules.validate(expense, widget.budget, now);
                      if (invalid != null) {
                        setState(() => error = invalid);
                        return;
                      }
                      Navigator.pop(context, expense);
                    },
                    child: CurrencyText(details ? 'Log it' : 'Continue')),
              ])));
}
