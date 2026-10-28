import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../design/design.dart';
import '../design/format.dart';
import '../../domain/rules/expense_rules.dart';

Future<int?> showAmountDialog(
        BuildContext context, int initial) =>
    showDialog<int>(
        context: context,
        builder: (_) => MoneyScope(
            currency: MoneyScope.read(context), child: _AmountDialog(initial)));

class _AmountDialog extends StatefulWidget {
  const _AmountDialog(this.initial);
  final int initial;
  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final controller = TextEditingController(
      text: MoneyScope.read(context).input(widget.initial));
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Planned amount'),
          content: Form(
              key: form,
              child: LabeledField(
                  label: 'Amount',
                  controller: controller,
                  currency: true,
                  validator: (value) => positiveMoney(value,
                      currency: MoneyScope.read(context)))),
          actions: [
            DialogActions(
                onCancel: () => Navigator.pop(context),
                onConfirm: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(
                        context,
                        moneyValue(controller.text,
                            currency: MoneyScope.read(context)));
                  }
                },
                confirmLabel: 'Save')
          ]);
}

class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => CurrencyText(text,
      style: type(13, color: secondaryText, weight: FontWeight.w500));
}

class LabeledField extends StatelessWidget {
  const LabeledField(
      {super.key,
      required this.label,
      required this.controller,
      this.currency = false,
      this.hintText,
      this.maxLength,
      this.validator,
      this.enabled = true});
  final String label;
  final TextEditingController controller;
  final bool currency;
  final String? hintText;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FormLabel(label),
        const SizedBox(height: 8),
        Semantics(
            label: label,
            child: TextFormField(
                key: ValueKey('input-$label'),
                controller: controller,
                style: buttonType(16),
                enabled: enabled,
                maxLength: maxLength,
                keyboardType: TextInputType.text,
                validator: validator,
                decoration: InputDecoration(
                    hintText: hintText ??
                        (currency
                            ? (label == 'Total funds' ? 'e.g. 3000' : 'e.g. 50')
                            : 'e.g. Coffee'),
                    hintStyle: type(14, color: tertiaryText),
                    fillColor: surfaceHigh,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    prefix: currency
                        ? const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: CurrencySymbol(size: 12))
                        : null))),
      ]);
}

class PickerButton extends StatelessWidget {
  const PickerButton(
      {super.key,
      required this.text,
      required this.icon,
      required this.onPressed,
      this.trailing,
      this.padding = const EdgeInsets.all(16),
      this.showArrow = true});
  final String text;
  final String? icon;
  final bool showArrow;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Material(
      color: surfaceHigh,
      borderRadius: BorderRadius.circular(controlRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: actionHeight),
              child: Padding(
                  padding: padding,
                  child: Row(children: [
                    if (icon != null) ...[
                      SourceIcon(icon!, color: secondaryText),
                      const SizedBox(width: listItemGap),
                    ],
                    Expanded(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: CurrencyText(text, style: buttonType(16)))),
                    if (trailing != null || showArrow) ...[
                      const SizedBox(width: spaceTight),
                      trailing ??
                          const SourceIcon('chevron-right',
                              size: 16, color: tertiaryText),
                    ],
                  ])))));
}

class DateControl extends StatelessWidget {
  const DateControl(this.label, this.value, this.onChanged,
      {super.key, this.first, this.last});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? first;
  final DateTime? last;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FormLabel(label),
        const SizedBox(height: 8),
        Semantics(
            label: label,
            child: PickerButton(
                key: ValueKey('date-$label'),
                text: dateText(value),
                icon: 'calendar',
                onPressed: () async {
                  final min = first ?? DateTime(2000),
                      max = last ?? DateTime(2100);
                  final initial = value.isBefore(min)
                      ? min
                      : value.isAfter(max)
                          ? max
                          : value;
                  final chosen = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: min,
                      lastDate: max);
                  if (chosen != null) onChanged(dayOnly(chosen));
                }))
      ]));
}

class ExpenseIcons extends StatelessWidget {
  const ExpenseIcons(this.value, this.onChanged, {super.key});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FormLabel('Icon'),
        const SizedBox(height: spaceTight),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final icon in productIcons)
            Semantics(
                label: '$icon icon',
                selected: icon == value,
                child: InkWell(
                    onTap: () => onChanged(icon),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                        width: 48,
                        height: 48,
                        decoration: panel(
                            radius: 14,
                            color: icon == value
                                ? const Color(0x2634D399)
                                : surfaceHigh),
                        child: Center(
                            child: SourceIcon(icon,
                                color: icon == value ? mint : secondaryText)))))
        ])
      ]);
}

class ExpenseTime extends StatelessWidget {
  const ExpenseTime(this.value, this.onChanged, {super.key});
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FormLabel('Time'),
        const SizedBox(height: 8),
        Semantics(
            label: 'Expense time',
            button: true,
            value: value.format(context),
            child: PickerButton(
                text: value.format(context),
                icon: 'clock',
                onPressed: () async {
                  final time = await showTimePicker(
                      context: context, initialTime: value);
                  if (time != null) onChanged(time);
                }))
      ]);
}

class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey, this.keyHeight = 56});
  final ValueChanged<String> onKey;
  final double keyHeight;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (final row in [
          ['1', '2', '3', '+'],
          ['4', '5', '6', '-'],
          ['7', '8', '9', '×'],
          ['0', '⌫', '=', '÷'],
          if (MoneyScope.of(context) == AppCurrency.eur) ['.']
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
                                  backgroundColor: surfaceHigh,
                                  foregroundColor: primaryText,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          controlRadius))),
                              child: row[i] == '⌫'
                                  ? Semantics(
                                      label: 'Delete last digit',
                                      child: const SourceIcon('backspace',
                                          size: 22, color: tertiaryText))
                                  : CurrencyText(row[i],
                                      style: type(22,
                                          role: TextRole.display,
                                          weight: FontWeight.w600,
                                          color: row[i] == '.'
                                              ? tertiaryText
                                              : primaryText)))))
                ],
                if (row.length == 1) ...[
                  const SizedBox(width: spaceSection),
                  const Spacer(flex: 3),
                ],
              ]))
      ]);
}
