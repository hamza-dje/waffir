import 'package:flutter/material.dart';
import 'design.dart';
import 'onboarding.dart';

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
                Text('Log an expense',
                    style: type(20, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Today · ${DateTime.now().day}/${DateTime.now().month}',
                    style: type(11, color: tertiaryText)),
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                    child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: amount.isEmpty ? '0' : amount,
                              style: type(52,
                                  weight: FontWeight.w600, spacing: -2)),
                          TextSpan(
                              text: ' DZD',
                              style: type(20, color: tertiaryText))
                        ]),
                        textAlign: TextAlign.center)),
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
                  TextField(
                      controller: name,
                      maxLength: 60,
                      decoration:
                          const InputDecoration(labelText: 'What was it for?'))
                else
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                          onPressed: () => setState(() => details = true),
                          child: Text('Add a note',
                              style: type(11, color: secondaryText)))),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(error!, style: type(13, color: caution))),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () {
                      final value = int.tryParse(amount);
                      if (value == null || value <= 0) {
                        setState(() => error = 'Enter a positive whole amount');
                        return;
                      }
                      Navigator.pop(context, (
                        name.text.trim().isEmpty ? 'Expense' : name.text.trim(),
                        value
                      ));
                    },
                    child: const Text('Log it')),
              ])));
}
