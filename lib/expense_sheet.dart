import 'package:flutter/material.dart';
import 'design.dart';
import 'onboarding.dart';
import 'budget_data.dart';
import 'editors.dart';

class ExpenseSheet extends StatefulWidget {
  const ExpenseSheet({super.key});
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
                    style: type(20, weight: FontWeight.w600)),
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
                    child: CurrencyText('${amount.isEmpty ? '0' : amount} DA',
                        style: type(52, weight: FontWeight.w600, spacing: -2),
                        textAlign: TextAlign.center)),
                if (!details)
                  AmountKeypad(
                      keyHeight: 52,
                      onKey: (key) => setState(() {
                            error = null;
                            if (key == '⌫') {
                              if (amount.isNotEmpty) {
                                amount = amount.substring(0, amount.length - 1);
                              }
                            } else if (amount.length < 9 &&
                                (key != '.' || !amount.contains('.'))) {
                              amount += key;
                            }
                          })),
                if (details)
                  LabeledField(
                      label: 'What was it for?',
                      controller: name,
                      maxLength: 60),
                if (details) ...[
                  ExpenseTime(time, (value) => setState(() => time = value)),
                  const SizedBox(height: 16),
                  ExpenseIcons(icon, (value) => setState(() => icon = value)),
                ],
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CurrencyText(error!,
                          style: type(13, color: caution))),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () {
                      final value = int.tryParse(amount);
                      if (value == null || value <= 0) {
                        setState(() => error = 'Enter a positive whole amount');
                        return;
                      }
                      if (!details) {
                        setState(() => details = true);
                        return;
                      }
                      if (name.text.trim().isEmpty) {
                        setState(() => error = 'Enter an expense name');
                        return;
                      }
                      final now = DateTime.now();
                      final date = DateTime(
                          now.year, now.month, now.day, time.hour, time.minute);
                      if (date.isAfter(now)) {
                        setState(() => error = 'Choose a time before now');
                        return;
                      }
                      Navigator.pop(context,
                          Expense(name.text.trim(), value, date, icon));
                    },
                    child: CurrencyText(details ? 'Log it' : 'Continue')),
              ])));
}
