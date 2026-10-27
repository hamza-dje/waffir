import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../design/design.dart';
import '../design/format.dart';

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
        CurrencyText(label,
            style: type(13, color: secondaryText, weight: FontWeight.w500)),
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
      required this.onPressed});
  final String text, icon;
  final VoidCallback onPressed;
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
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    SourceIcon(icon, color: secondaryText),
                    const SizedBox(width: listItemGap),
                    Expanded(child: Text(text, style: buttonType(16))),
                    const SizedBox(width: spaceTight),
                    const SourceIcon('chevron-right',
                        size: 16, color: tertiaryText),
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
        CurrencyText(label,
            style: type(13, color: secondaryText, weight: FontWeight.w500)),
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
        sectionLabel('Icon'),
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
        Text('Time',
            style: type(13, color: secondaryText, weight: FontWeight.w500)),
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
          ['0', '⌫', '=', '÷']
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
                ]
              ]))
      ]);
}
