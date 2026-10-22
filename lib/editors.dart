import 'package:flutter/material.dart';
import 'budget_data.dart';
import 'design.dart';

String dateText(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String money(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
String? positiveMoney(String? value) {
  final amount = int.tryParse(value ?? '');
  return amount == null || amount <= 0 || amount > 999999999
      ? 'Enter a positive whole amount'
      : null;
}

AppBar editorBar(BuildContext context, String title) => AppBar(
    leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
        icon: const SourceIcon('arrow-left')),
    title: CurrencyText(title, style: type(20, weight: FontWeight.w600)));

Future<bool> confirmAction(BuildContext context, String title, String message,
        String action) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: surface,
              title: CurrencyText(title),
              content: CurrencyText(message),
              actions: [
                DialogActions(
                    onCancel: () => Navigator.pop(context, false),
                    onConfirm: () => Navigator.pop(context, true),
                    confirmLabel: action)
              ],
            )) ??
    false;

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
            child: OutlinedButton(
                key: ValueKey('date-$label'),
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
                },
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide.none,
                    backgroundColor: surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: Row(children: [
                  const SourceIcon('calendar', color: secondaryText),
                  const SizedBox(width: 12),
                  Expanded(
                      child: CurrencyText(dateText(value),
                          style: type(14, weight: FontWeight.w500))),
                  const SourceIcon('chevron-right',
                      size: 16, color: tertiaryText),
                ])))
      ]));
}

class BudgetEditor extends StatefulWidget {
  const BudgetEditor({super.key, required this.initial, required this.onSave});
  final BudgetRecord initial;
  final Future<bool> Function(BudgetRecord) onSave;
  @override
  State<BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<BudgetEditor> {
  final form = GlobalKey<FormState>();
  late final funds = TextEditingController(text: '${widget.initial.funds}');
  late DateTime start = widget.initial.start, end = widget.initial.end;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    funds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: editorBar(context, 'Edit budget'),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            CurrencyText('Correct your budget',
                style: type(26, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            CurrencyText(
                'Your expenses stay in this budget. All figures update after saving.',
                style: type(13, color: secondaryText)),
            const SizedBox(height: 24),
            LabeledField(
                label: 'Total funds',
                currency: true,
                controller: funds,
                enabled: !busy,
                validator: positiveMoney),
            const SizedBox(height: 20),
            DateControl('Start date', start, (d) => setState(() => start = d)),
            DateControl('End date', end, (d) => setState(() => end = d)),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CurrencyText(error!, style: type(13, color: caution))),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        final next = widget.initial.copyWith(
                            funds: int.parse(funds.text),
                            start: start,
                            end: end,
                            legacy: false);
                        final invalid = next.validate();
                        if (invalid != null) {
                          setState(() => error = invalid);
                          return;
                        }
                        setState(() => busy = true);
                        final ok = await widget.onSave(next);
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          setState(() => busy = false);
                        }
                      },
                child: CurrencyText(busy ? 'Saving…' : 'Save budget')),
          ])));
}

class ExpenseEditor extends StatefulWidget {
  const ExpenseEditor({super.key, required this.expense, required this.budget});
  final Expense expense;
  final BudgetRecord budget;
  @override
  State<ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<ExpenseEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.expense.label);
  late final amount = TextEditingController(text: '${widget.expense.amount}');
  late DateTime date = dayOnly(widget.expense.date);
  late String icon = widget.expense.icon;
  late TimeOfDay time = TimeOfDay.fromDateTime(widget.expense.date);
  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: editorBar(context, 'Edit expense'),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            LabeledField(
                label: 'Expense name',
                controller: name,
                maxLength: 60,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name' : null),
            const SizedBox(height: 16),
            LabeledField(
                label: 'Amount',
                currency: true,
                controller: amount,
                validator: positiveMoney),
            const SizedBox(height: 20),
            DateControl('Expense date', date, (d) => setState(() => date = d),
                first: widget.budget.start,
                last: [
                  widget.budget.end,
                  dayOnly(widget.budget.closedAt ?? DateTime.now()),
                  dayOnly(DateTime.now())
                ].reduce((a, b) => a.isBefore(b) ? a : b)),
            ExpenseTime(time, (value) => setState(() => time = value)),
            const SizedBox(height: 16),
            ExpenseIcons(icon, (value) => setState(() => icon = value)),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  final chosen = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute);
                  if (chosen.isAfter(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Choose a time before now')));
                    return;
                  }
                  Navigator.pop(
                      context,
                      Expense(name.text.trim(), int.parse(amount.text), chosen,
                          icon));
                },
                child: const CurrencyText('Save expense')),
            const SizedBox(height: 12),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: caution, foregroundColor: background),
                onPressed: () async {
                  final yes = await confirmAction(context, 'Delete expense?',
                      'This entry will be removed from the budget.', 'Delete');
                  if (yes && context.mounted) Navigator.pop(context, 'delete');
                },
                child: const CurrencyText('Delete expense')),
          ])));
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, this.initial});
  final UsualProduct? initial;
  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.initial?.name ?? '');
  late final price =
      TextEditingController(text: widget.initial?.price.toString() ?? '');
  late String icon = widget.initial?.icon ?? 'banknote';
  @override
  void dispose() {
    name.dispose();
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: editorBar(
          context, widget.initial == null ? 'Add product' : 'Edit product'),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            LabeledField(
                label: 'Product name',
                controller: name,
                maxLength: 40,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name' : null),
            const SizedBox(height: 16),
            LabeledField(
                label: 'Usual price',
                currency: true,
                controller: price,
                validator: positiveMoney),
            const SizedBox(height: 24),
            ExpenseIcons(icon, (value) => setState(() => icon = value)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(
                        context,
                        UsualProduct(
                            name.text.trim(), int.parse(price.text), icon));
                  }
                },
                child: const CurrencyText('Save product')),
            if (widget.initial != null)
              TextButton(
                  onPressed: () async {
                    final yes = await confirmAction(context, 'Remove product?',
                        'Past expenses will stay unchanged.', 'Remove');
                    if (yes && context.mounted) {
                      Navigator.pop(context, 'delete');
                    }
                  },
                  child: CurrencyText('Remove product',
                      style: type(14, color: caution))),
          ])));
}

class ProductList extends StatelessWidget {
  const ProductList(
      {super.key,
      required this.products,
      required this.onChanged,
      this.enabled = true});
  final List<UsualProduct> products;
  final ValueChanged<List<UsualProduct>> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (products.isEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CurrencyText(
                  'Add the things you usually spend on. One tap will log the usual price.',
                  style: type(13, color: secondaryText, height: 1.5))),
        for (var i = 0; i < products.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      horizontalTitleGap: 20,
                      leading: Opacity(
                          opacity: .55,
                          child: SourceIcon(products[i].icon,
                              color: secondaryText)),
                      title: CurrencyText(products[i].name,
                          style: type(14, weight: FontWeight.w500)),
                      subtitle: CurrencyText('${products[i].price} DA',
                          style: type(12, color: tertiaryText)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Edit', style: type(12, color: secondaryText)),
                        const SizedBox(width: 4),
                        const SourceIcon('chevron-right',
                            size: 16, color: secondaryText),
                      ]),
                      onTap: !enabled
                          ? null
                          : () async {
                              final updated = await Navigator.push<Object>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProductEditor(initial: products[i])));
                              if (updated is UsualProduct) {
                                onChanged([...products]..[i] = updated);
                              } else if (updated == 'delete') {
                                onChanged([...products]..removeAt(i));
                              }
                            },
                      onLongPress: !enabled
                          ? null
                          : () async {
                              final yes = await confirmAction(
                                  context,
                                  'Remove product?',
                                  'Past expenses will stay unchanged.',
                                  'Remove');
                              if (yes) onChanged([...products]..removeAt(i));
                            }))),
        if (products.isNotEmpty) const SizedBox(height: 16),
        FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(
                    fontFamily: 'RedHatDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            onPressed: !enabled
                ? null
                : () async {
                    final product = await Navigator.push<UsualProduct>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProductEditor()));
                    if (product != null) onChanged([...products, product]);
                  },
            icon: const SourceIcon('plus', size: 17, color: Color(0xFF06251A)),
            label: const CurrencyText('Add product')),
        if (products.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CurrencyText(
                  'Tap to edit or remove. Past expenses stay unchanged.',
                  style: type(11, color: tertiaryText))),
      ]);
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
            child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final time = await showTimePicker(
                      context: context, initialTime: value);
                  if (time != null) onChanged(time);
                },
                child: InputDecorator(
                    decoration: const InputDecoration(
                        fillColor: surfaceHigh,
                        contentPadding: EdgeInsets.all(16),
                        prefixIcon: Padding(
                            padding: EdgeInsets.all(14),
                            child: SourceIcon('clock', color: secondaryText)),
                        suffixIcon: Padding(
                            padding: EdgeInsets.all(16),
                            child: SourceIcon('chevron-right',
                                size: 16, color: tertiaryText))),
                    child: Text(value.format(context), style: type(16)))))
      ]);
}
