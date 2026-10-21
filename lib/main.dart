import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_settings.dart';

const mint = Color(0xFF34D399);
const background = Color(0xFF0F1115);
const surface = Color(0xFF171A21);

void main() => runApp(const WafirApp());

class WafirApp extends StatelessWidget {
  const WafirApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Wafir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: background,
          colorScheme: const ColorScheme.dark(primary: mint, surface: surface),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 54),
              foregroundColor: const Color(0xFF06251A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        home: const BudgetScreen(),
      );
}

class Expense {
  Expense(this.label, this.amount, this.date);
  final String label;
  final int amount;
  final DateTime date;
  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'date': date.toIso8601String(),
      };
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        json['label'] as String,
        json['amount'] as int,
        DateTime.parse(json['date'] as String),
      );
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with WidgetsBindingObserver {
  SharedPreferences? prefs;
  int? budget;
  int fixedCosts = 0;
  int saved = 0;
  String goalName = '';
  int goalTarget = 0;
  int days = 30;
  int tab = 0;
  DateTime start = DateTime.now();
  List<Expense> expenses = [];
  List<Expense> pastExpenses = [];
  bool renewing = false;
  int draftDays = 30;
  Timer? dateTimer;
  String? loadError;
  final budgetInput = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    dateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    load();
  }

  @override
  void dispose() {
    budgetInput.dispose();
    dateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  Future<void> load() async {
    try {
      final store = await SharedPreferences.getInstance();
      final raw = store.getString('budget_state');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        budget = data['budget'] as int;
        fixedCosts = (data['fixedCosts'] ?? 0) as int;
        saved = (data['saved'] ?? 0) as int;
        goalName = (data['goalName'] ?? '') as String;
        goalTarget = (data['goalTarget'] ?? 0) as int;
        days = data['days'] as int;
        start = DateTime.parse(data['start'] as String);
        expenses = (data['expenses'] as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
        pastExpenses = ((data['pastExpenses'] ?? []) as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
        draftDays = days;
      }
      if (mounted) setState(() => prefs = store);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              loadError = 'Could not load your budget. Please restart the app.',
        );
      }
    }
  }

  Future<bool> persist(
    int amount,
    List<Expense> entries, {
    DateTime? periodStart,
    int? periodDays,
    List<Expense>? archive,
    BudgetPlan? plan,
  }) async {
    try {
      final ok = await prefs!.setString(
        'budget_state',
        jsonEncode({
          'budget': plan?.funds ?? amount,
          'fixedCosts': plan?.fixed ?? fixedCosts,
          'saved': plan?.saved ?? saved,
          'goalName': plan?.goal ?? goalName,
          'goalTarget': plan?.target ?? goalTarget,
          'days': periodDays ?? days,
          'start': (periodStart ?? start).toIso8601String(),
          'expenses': entries.map((e) => e.toJson()).toList(),
          'pastExpenses':
              (archive ?? pastExpenses).map((e) => e.toJson()).toList(),
        }),
      );
      if (!ok) throw StateError('Save failed');
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
      return false;
    }
  }

  int get spent => expenses.fold(0, (sum, e) => sum + e.amount);
  int get remainingDays {
    final today = DateUtils.dateOnly(DateTime.now());
    return (days - today.difference(DateUtils.dateOnly(start)).inDays).clamp(
      0,
      days,
    );
  }

  bool get expired => budget != null && remainingDays == 0;
  int get remaining => budget! - fixedCosts - saved - spent;
  int get allowance =>
      remainingDays == 0 ? 0 : (remaining / remainingDays).floor();

  Future<void> editBudget() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => BudgetSettingsPage(
                initial: (
                  funds: budget!,
                  fixed: fixedCosts,
                  saved: saved,
                  goal: goalName,
                  target: goalTarget
                ),
                onSave: (plan) async {
                  if (saving) return false;
                  setState(() => saving = true);
                  final ok = await persist(budget!, expenses, plan: plan);
                  if (mounted)
                    setState(() {
                      if (ok) {
                        budget = plan.funds;
                        fixedCosts = plan.fixed;
                        saved = plan.saved;
                        goalName = plan.goal;
                        goalTarget = plan.target;
                      }
                      saving = false;
                    });
                  return ok;
                })));
  }

  Future<void> log(String label, int amount) async {
    if (saving || expired) return;
    setState(() => saving = true);
    final next = [...expenses, Expense(label, amount, DateTime.now())];
    final ok = await persist(budget!, next);
    if (mounted) {
      setState(() {
        if (ok) expenses = next;
        saving = false;
      });
    }
  }

  Future<void> customExpense() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final result = await showModalBottomSheet<(String, int)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Log an expense',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What was it for?',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount in DZD (whole dinars)',
                ),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Enter a positive whole amount'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(context, (
                      name.text.trim(),
                      int.parse(amount.text),
                    ));
                  }
                },
                child: const Text('Log it'),
              ),
            ],
          ),
        ),
      ),
    );
    // The sheet route may still animate after its result resolves.
    if (result != null && mounted) await log(result.$1, result.$2);
  }

  Widget brand() => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/dzd.svg',
              semanticsLabel: 'Wafir DZD symbol',
              colorFilter: const ColorFilter.mode(
                Color(0xFF06251A),
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
              child: Text(
            'Wafir / وفّر',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          )),
          if (budget != null && !renewing)
            IconButton(
                onPressed: saving ? null : editBudget,
                tooltip: 'Budget settings',
                icon: const Icon(Icons.settings_outlined)),
        ],
      );

  Widget setup() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Text(
            'Make room for\nwhat matters.',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'A little clarity for your everyday money.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Text(renewing
              ? 'Start a new budget period'
              : 'How often do you budget?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              for (final n in [30, 7])
                ChoiceChip(
                  label:
                      Text(n == 30 ? 'Monthly · 30 days' : 'Weekly · 7 days'),
                  selected: draftDays == n,
                  onSelected:
                      saving ? null : (_) => setState(() => draftDays = n),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: budgetInput,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total funds',
              suffixText: 'DZD',
              helperText: 'Set fixed costs and savings in Budget settings.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final amount = int.tryParse(budgetInput.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Enter a positive budget in whole dinars.'),
                        ),
                      );
                      return;
                    }
                    setState(() => saving = true);
                    final nextStart = DateTime.now();
                    if (fixedCosts + saved > amount) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'New funds must cover fixed costs and saved money. Edit Budget settings first.')));
                      setState(() => saving = false);
                      return;
                    }
                    final archive = [...pastExpenses, ...expenses];
                    final ok = await persist(amount, [],
                        periodStart: nextStart,
                        periodDays: draftDays,
                        archive: archive);
                    if (mounted) {
                      setState(() {
                        if (ok) {
                          budget = amount;
                          days = draftDays;
                          start = nextStart;
                          expenses = [];
                          pastExpenses = archive;
                          renewing = false;
                          tab = 0;
                        }
                        saving = false;
                      });
                    }
                  },
            child: Text(saving
                ? 'Saving…'
                : renewing
                    ? 'Confirm new period'
                    : 'Start my budget'),
          ),
          if (renewing)
            TextButton(
                onPressed:
                    saving ? null : () => setState(() => renewing = false),
                child: const Text('Cancel')),
        ],
      );

  Widget entries(List<Expense> items) => items.isEmpty
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Nothing logged yet. Start with your next expense.',
            style: TextStyle(color: Colors.white60),
          ),
        )
      : Column(
          children: [
            for (final e in items.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_outlined, color: mint),
                title: Text(e.label),
                subtitle: Text(
                  '${e.date.day}/${e.date.month} · ${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}',
                ),
                trailing: Text(
                  '−${e.amount} DZD',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        );

  Widget today() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          if (expired) ...[
            const Text('Your budget period has ended.',
                style: TextStyle(color: Color(0xFFF5B84A), fontSize: 20)),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => setState(() {
                      renewing = true;
                      budgetInput.clear();
                      draftDays = days;
                    }),
                child: const Text('Start new period')),
            const SizedBox(height: 16),
          ],
          Text(
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 36),
          Text(
            '$allowance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 88,
              height: 1.1,
              letterSpacing: -4,
              color: allowance < 0 ? const Color(0xFFF5B84A) : mint,
            ),
          ),
          const Text(
            'DZD per day',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '$remaining DZD left · $remainingDays days remaining',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 36),
          if (saved > 0 || goalTarget > 0) ...[
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goalName.isEmpty ? 'Your savings' : goalName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('$saved / $goalTarget DZD saved'),
                          if (goalTarget > 0) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                                value: (saved / goalTarget).clamp(0, 1),
                                semanticsLabel: 'Savings goal progress'),
                            if (saved >= goalTarget) const Text('Goal reached'),
                          ],
                          TextButton(
                              onPressed: saving ? null : editBudget,
                              child: const Text('Update savings')),
                        ]))),
            const SizedBox(height: 24),
          ],
          const Text(
            'QUICK LOG',
            style: TextStyle(
                color: Colors.white54, letterSpacing: 2, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                ('Coffee', 50),
                ('Sandwich', 150),
                ('Bus', 30),
                ('Water', 30),
                ('Meal', 300),
              ])
                OutlinedButton(
                  onPressed:
                      saving || expired ? null : () => log(item.$1, item.$2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('${item.$1}\n${item.$2} DZD'),
                ),
              FilledButton(
                onPressed: saving || expired ? null : customExpense,
                child: const Text('+ Add'),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Text(
            "Today's log",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          entries(
            expenses
                .where((e) => DateUtils.isSameDay(e.date, DateTime.now()))
                .toList(),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: prefs == null
                  ? Center(
                      child: loadError == null
                          ? const CircularProgressIndicator()
                          : Text(loadError!),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        brand(),
                        if (budget == null || renewing)
                          setup()
                        else if (tab == 0)
                          today()
                        else ...[
                          const SizedBox(height: 32),
                          const Text(
                            'History',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$spent DZD spent this period',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          entries(expenses),
                          if (pastExpenses.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text('Previous periods',
                                style: TextStyle(fontSize: 20)),
                            entries(pastExpenses),
                          ],
                        ],
                      ],
                    ),
            ),
          ),
        ),
        bottomNavigationBar: budget == null
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (value) => setState(() => tab = value),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.today_outlined),
                    label: 'Today',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history),
                    label: 'History',
                  ),
                ],
              ),
      );
}
