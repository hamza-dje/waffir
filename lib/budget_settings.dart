import 'package:flutter/material.dart';

typedef BudgetPlan = ({
  int funds,
  int fixed,
  int saved,
  String goal,
  int target
});

class BudgetSettingsPage extends StatefulWidget {
  const BudgetSettingsPage(
      {super.key, required this.initial, required this.onSave});
  final BudgetPlan initial;
  final Future<bool> Function(BudgetPlan) onSave;
  @override
  State<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends State<BudgetSettingsPage> {
  final form = GlobalKey<FormState>();
  late final funds = TextEditingController(text: '${widget.initial.funds}');
  late final fixed = TextEditingController(text: '${widget.initial.fixed}');
  late final saved = TextEditingController(text: '${widget.initial.saved}');
  late final goal = TextEditingController(text: widget.initial.goal);
  late final target = TextEditingController(text: '${widget.initial.target}');
  bool saving = false;

  @override
  void dispose() {
    for (final controller in [funds, fixed, saved, goal, target]) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget money(String label, TextEditingController controller,
          {bool positive = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
              controller: controller,
              enabled: !saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: label, suffixText: 'DZD'),
              validator: (value) {
                final number = int.tryParse(value ?? '');
                if (number == null || number < (positive ? 1 : 0)) {
                  return positive
                      ? 'Enter a positive whole amount.'
                      : 'Enter zero or a positive whole amount.';
                }
                return null;
              }));

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Budget settings')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                  key: form,
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    const Text('Set money aside first.',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    const Text(
                        'Fixed costs and saved money are excluded from your daily allowance. Expenses already logged are deducted once.'),
                    const SizedBox(height: 24),
                    money('Total funds', funds, positive: true),
                    money('Fixed costs', fixed),
                    money('Savings reserved', saved),
                    TextFormField(
                        controller: goal,
                        enabled: !saving,
                        maxLength: 60,
                        decoration: const InputDecoration(
                            labelText: 'Savings goal name'),
                        validator: (value) =>
                            (int.tryParse(target.text) ?? 0) > 0 &&
                                    (value ?? '').trim().isEmpty
                                ? 'Name your savings goal.'
                                : null),
                    const SizedBox(height: 16),
                    money('Goal target', target),
                    FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                final next = (
                                  funds: int.parse(funds.text),
                                  fixed: int.parse(fixed.text),
                                  saved: int.parse(saved.text),
                                  goal: goal.text.trim(),
                                  target: int.parse(target.text)
                                );
                                if (next.fixed + next.saved > next.funds) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Fixed costs and savings exceed total funds.')));
                                  return;
                                }
                                setState(() => saving = true);
                                final ok = await widget.onSave(next);
                                if (!context.mounted) return;
                                if (ok)
                                  Navigator.pop(context);
                                else
                                  setState(() => saving = false);
                              },
                        child: Text(saving ? 'Saving…' : 'Save budget')),
                  ])))));
}
