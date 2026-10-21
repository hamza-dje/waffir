import 'package:flutter/material.dart';
import 'design.dart';

class BudgetOnboarding extends StatefulWidget {
  const BudgetOnboarding(
      {super.key,
      required this.onSave,
      this.initialDays = 30,
      this.renewing = false,
      this.onCancel});
  final Future<bool> Function(int funds, int days) onSave;
  final int initialDays;
  final bool renewing;
  final VoidCallback? onCancel;
  @override
  State<BudgetOnboarding> createState() => _BudgetOnboardingState();
}

class _BudgetOnboardingState extends State<BudgetOnboarding> {
  int step = 0;
  late int days = widget.initialDays;
  bool custom = false;
  bool busy = false;
  final amount = TextEditingController();
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final end = await showDatePicker(
        context: context,
        initialDate: now.add(Duration(days: days)),
        firstDate: now.add(const Duration(days: 1)),
        lastDate: now.add(const Duration(days: 3660)));
    if (end != null) {
      setState(() {
        days = end.difference(now).inDays;
        custom = true;
      });
    }
  }

  Widget option(String title, String detail, String icon, bool selected,
          VoidCallback action) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: action,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          gradient: selected
                              ? const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF193025), surface])
                              : null,
                          border: Border.all(
                              color: selected ? mint : Colors.transparent,
                              width: 1.5)),
                      child: Row(children: [
                        Container(
                            width: 40,
                            height: 40,
                            decoration: panel(
                                radius: 12,
                                color: selected
                                    ? const Color(0x1F34D399)
                                    : surfaceHigh),
                            child: Center(
                                child: SourceIcon(icon,
                                    color: selected ? mint : secondaryText))),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  style: type(15, weight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(detail, style: type(11, color: tertiaryText))
                            ])),
                        if (selected)
                          const SourceIcon('check', color: mint, size: 18)
                      ])))));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              for (var i = 0; i < 3; i++)
                                Container(
                                    width: 24,
                                    height: 4,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: panel(
                                        radius: 2,
                                        color: i <= step ? mint : surfaceHigh))
                            ]),
                            const SizedBox(height: 28),
                            if (step == 0) ...[
                              Text('How often do\nyou budget?',
                                  style: type(26,
                                      weight: FontWeight.w600,
                                      spacing: -.65,
                                      height: 1.15)),
                              const SizedBox(height: 8),
                              Text(
                                  'Pick the rhythm that fits your money. You can change it later.',
                                  style: type(13,
                                      color: secondaryText, height: 1.55)),
                              const SizedBox(height: 28),
                              option(
                                  'Monthly',
                                  'Most common',
                                  'calendar',
                                  !custom && days == 30,
                                  () => setState(() {
                                        days = 30;
                                        custom = false;
                                      })),
                              option(
                                  'Weekly',
                                  'Fits weekly shopping',
                                  'clock',
                                  !custom && days == 7,
                                  () => setState(() {
                                        days = 7;
                                        custom = false;
                                      })),
                              option(
                                  'Until scholarship',
                                  custom
                                      ? '$days days · tap to change'
                                      : 'Custom end date',
                                  'banknote',
                                  custom,
                                  chooseDate),
                            ] else ...[
                              Text(
                                  'How much do you\nhave ${days == 30 ? 'this month' : days == 7 ? 'this week' : 'until then'}?',
                                  style: type(26,
                                      weight: FontWeight.w600,
                                      spacing: -.65,
                                      height: 1.15)),
                              const SizedBox(height: 8),
                              Text('Total amount, before any fixed costs.',
                                  style: type(13, color: secondaryText)),
                              const SizedBox(height: 28),
                              Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Expanded(
                                        child: TextField(
                                            controller: amount,
                                            readOnly: true,
                                            showCursor: false,
                                            style: type(64,
                                                weight: FontWeight.w600,
                                                spacing: -2),
                                            decoration: const InputDecoration(
                                                hintText: '0',
                                                labelText: 'Total funds',
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior.never,
                                                filled: false,
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.zero))),
                                    Text('DZD',
                                        style: type(16, color: tertiaryText))
                                  ]),
                              const SizedBox(height: 24),
                              AmountKeypad(
                                  onKey: (key) => setState(() {
                                        if (key == '⌫') {
                                          if (amount.text.isNotEmpty) {
                                            amount.text = amount.text.substring(
                                                0, amount.text.length - 1);
                                          }
                                        } else if (amount.text.length < 9 &&
                                            (key != '.' ||
                                                !amount.text.contains('.'))) {
                                          amount.text += key;
                                        }
                                      })),
                            ],
                            const Spacer(),
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: busy
                                    ? null
                                    : () async {
                                        if (step == 0) {
                                          setState(() => step = 1);
                                          return;
                                        }
                                        final funds = int.tryParse(amount.text);
                                        if (funds == null || funds <= 0) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Enter a positive budget in whole dinars.')));
                                          return;
                                        }
                                        setState(() => busy = true);
                                        final ok =
                                            await widget.onSave(funds, days);
                                        if (mounted && !ok) {
                                          setState(() => busy = false);
                                        }
                                      },
                                child: Text(busy ? 'Saving…' : 'Continue')),
                            if (step == 1 || widget.renewing)
                              TextButton(
                                  onPressed: busy
                                      ? null
                                      : () {
                                          if (step == 1) {
                                            setState(() => step = 0);
                                          } else {
                                            widget.onCancel?.call();
                                          }
                                        },
                                  child: Text(step == 1 ? 'Back' : 'Cancel')),
                          ]))))));
}

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey, this.keyHeight = 56});
  final ValueChanged<String> onKey;
  final double keyHeight;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['.', '0', '⌫']
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                      child: SizedBox(
                          height: keyHeight,
                          child: TextButton(
                              onPressed: () => onKey(row[i]),
                              style: TextButton.styleFrom(
                                  backgroundColor:
                                      row[i] == '.' || row[i] == '⌫'
                                          ? Colors.transparent
                                          : surface,
                                  foregroundColor: primaryText,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                              child: Text(row[i],
                                  style: type(22, weight: FontWeight.w500)))))
                ]
              ]))
      ]);
}
