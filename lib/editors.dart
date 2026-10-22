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
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const CurrencyText('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: CurrencyText(action)),
                ])) ??
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
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
          onPressed: () async {
            final min = first ?? DateTime(2000), max = last ?? DateTime(2100);
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
                  borderRadius: BorderRadius.circular(16))),
          child: Row(children: [
            const SourceIcon('calendar', color: secondaryText),
            const SizedBox(width: 12),
            Expanded(
                child:
                    CurrencyText(label, style: type(13, color: secondaryText))),
            CurrencyText(dateText(value),
                style: type(13, weight: FontWeight.w500))
          ])));
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
            TextFormField(
                controller: funds,
                enabled: !busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Total funds', suffix: CurrencySymbol(size: 18)),
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
            TextFormField(
                controller: name,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Expense name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name' : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Amount', suffix: CurrencySymbol(size: 18)),
                validator: positiveMoney),
            const SizedBox(height: 20),
            DateControl('Expense date', date, (d) => setState(() => date = d),
                first: widget.budget.start,
                last: [
                  widget.budget.end,
                  dayOnly(widget.budget.closedAt ?? DateTime.now()),
                  dayOnly(DateTime.now())
                ].reduce((a, b) => a.isBefore(b) ? a : b)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  final old = widget.expense.date;
                  Navigator.pop(
                      context,
                      Expense(
                          name.text.trim(),
                          int.parse(amount.text),
                          DateTime(date.year, date.month, date.day, old.hour,
                              old.minute, old.second),
                          widget.expense.icon));
                },
                child: const CurrencyText('Save expense')),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () async {
                  final yes = await confirmAction(context, 'Delete expense?',
                      'This entry will be removed from the budget.', 'Delete');
                  if (yes && context.mounted) Navigator.pop(context, 'delete');
                },
                child: CurrencyText('Delete expense',
                    style: type(14, color: caution))),
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
            TextFormField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name' : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Usual price', suffix: CurrencySymbol(size: 18)),
                validator: positiveMoney),
            const SizedBox(height: 24),
            sectionLabel('Icon'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final choice in productIcons)
                Semantics(
                    label: '$choice icon',
                    selected: choice == icon,
                    button: true,
                    child: InkWell(
                        onTap: () => setState(() => icon = choice),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: choice == icon
                                  ? const Color(0x1F34D399)
                                  : surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                                child: SourceIcon(choice,
                                    color: choice == icon
                                        ? mint
                                        : secondaryText)))))
            ]),
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
                      leading:
                          SourceIcon(products[i].icon, color: secondaryText),
                      title: CurrencyText(products[i].name,
                          style: type(14, weight: FontWeight.w500)),
                      subtitle: CurrencyText('${products[i].price} DA',
                          style: type(12, color: tertiaryText)),
                      trailing: const SourceIcon('chevron-right',
                          size: 16, color: tertiaryText),
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
                              } else if (updated == 'delete')
                                onChanged([...products]..removeAt(i));
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
        OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final product = await Navigator.push<UsualProduct>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProductEditor()));
                    if (product != null) onChanged([...products, product]);
                  },
            icon: const SourceIcon('plus', color: mint),
            label: const CurrencyText('Add product')),
        if (products.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CurrencyText(
                  'Tap to edit or remove. Past expenses stay unchanged.',
                  style: type(11, color: tertiaryText))),
      ]);
}
