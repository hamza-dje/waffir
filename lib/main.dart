import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _BudgetScreenState extends State<BudgetScreen> {
  SharedPreferences? prefs;
  int? budget;
  int days = 30;
  int tab = 0;
  DateTime start = DateTime.now();
  List<Expense> expenses = [];
  String? loadError;
  final budgetInput = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    budgetInput.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final store = await SharedPreferences.getInstance();
      final raw = store.getString('budget_state');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        budget = data['budget'] as int;
        days = data['days'] as int;
        start = DateTime.parse(data['start'] as String);
        expenses = (data['expenses'] as List)
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList();
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

  Future<bool> persist(int amount, List<Expense> entries) async {
    try {
      final ok = await prefs!.setString(
        'budget_state',
        jsonEncode({
          'budget': amount,
          'days': days,
          'start': start.toIso8601String(),
          'expenses': entries.map((e) => e.toJson()).toList(),
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
      1,
      days,
    );
  }

  int get allowance => ((budget! - spent) / remainingDays).floor();

  Future<void> log(String label, int amount) async {
    if (saving) return;
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
      const Text(
        'Wafir / وفّر',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
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
      const Text('How often do you budget?'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        children: [
          for (final n in [30, 7])
            ChoiceChip(
              label: Text(n == 30 ? 'Monthly · 30 days' : 'Weekly · 7 days'),
              selected: days == n,
              onSelected: (_) => setState(() => days = n),
            ),
        ],
      ),
      const SizedBox(height: 24),
      TextField(
        controller: budgetInput,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Available budget',
          suffixText: 'DZD',
          helperText: 'After fixed costs and money set aside for savings',
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
                      content: Text('Enter a positive budget in whole dinars.'),
                    ),
                  );
                  return;
                }
                setState(() => saving = true);
                start = DateTime.now();
                final ok = await persist(amount, []);
                if (mounted) {
                  setState(() {
                    if (ok) budget = amount;
                    saving = false;
                  });
                }
              },
        child: Text(saving ? 'Saving…' : 'Start my budget'),
      ),
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
        '${budget! - spent} DZD left · $remainingDays days remaining',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white60),
      ),
      const SizedBox(height: 36),
      const Text(
        'QUICK LOG',
        style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12),
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
              onPressed: saving ? null : () => log(item.$1, item.$2),
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
            onPressed: saving ? null : customExpense,
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
                    if (budget == null)
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
