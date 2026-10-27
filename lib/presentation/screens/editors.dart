import '../widgets/form_controls.dart';
import '../widgets/editor_actions.dart';
import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/rules/expense_rules.dart';
import '../design/design.dart';

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
                style:
                    type(26, role: TextRole.display, weight: FontWeight.w600)),
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
                            funds: moneyValue(funds.text)!,
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
                validator: ExpenseRules.nameError),
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
                  final expense = Expense(
                      name.text.trim(), moneyValue(amount.text)!, chosen, icon);
                  final invalid = ExpenseRules.validate(
                      expense, widget.budget, DateTime.now(),
                      correction: true);
                  if (invalid != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(invalid)));
                    return;
                  }
                  Navigator.pop(context, expense);
                },
                child: const CurrencyText('Save expense')),
            const SizedBox(height: 12),
            FilledButton(
                style: deleteAction(),
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
                validator: ExpenseRules.nameError),
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
                            name.text.trim(), moneyValue(price.text)!, icon));
                  }
                },
                child: const CurrencyText('Save product')),
            if (widget.initial != null)
              FilledButton(
                  style: deleteAction(),
                  onPressed: () async {
                    final yes = await confirmAction(context, 'Remove product?',
                        'Past expenses will stay unchanged.', 'Remove');
                    if (yes && context.mounted) {
                      Navigator.pop(context, 'delete');
                    }
                  },
                  child: const CurrencyText('Remove product')),
          ])));
}

Future<Object?> editProduct(BuildContext context, UsualProduct? initial) =>
    Navigator.push<Object>(context,
        MaterialPageRoute(builder: (_) => ProductEditor(initial: initial)));
