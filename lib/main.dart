import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_settings.dart';
import 'price_check.dart';

import 'design.dart';
import 'onboarding.dart';
import 'expense_sheet.dart';

void main() => runApp(const WafirApp());

class WafirApp extends StatelessWidget {
  const WafirApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Waffir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Geist',
          fontFamilyFallback: const ['Rubik'],
          brightness: Brightness.dark,
          textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: primaryText,
              displayColor: primaryText,
              fontFamily: 'Geist'),
          appBarTheme: const AppBarTheme(
              backgroundColor: background,
              surfaceTintColor: Colors.transparent),
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
                  if (mounted) {
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
                  }
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
    final result = await showModalBottomSheet<(String, int)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const ExpenseSheet(),
    );
    if (result != null && mounted) await log(result.$1, result.$2);
  }

  Future<bool> startPeriod(int amount, int periodDays) async {
    if (saving) return false;
    if (fixedCosts + saved > amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'New funds must cover fixed costs and saved money. Edit Budget settings first.')));
      return false;
    }
    setState(() => saving = true);
    final nextStart = DateTime.now();
    final archive = [...pastExpenses, ...expenses];
    final ok = await persist(amount, [],
        periodStart: nextStart, periodDays: periodDays, archive: archive);
    if (mounted)
      setState(() {
        if (ok) {
          budget = amount;
          days = periodDays;
          start = nextStart;
          expenses = [];
          pastExpenses = archive;
          renewing = false;
          tab = 0;
        }
        saving = false;
      });
    return ok;
  }

  String iconFor(String label) => switch (label.toLowerCase()) {
        'coffee' => 'coffee',
        'sandwich' => 'sandwich',
        'bus' => 'bus',
        'water' => 'droplet',
        'meal' => 'utensils',
        _ => 'banknote',
      };

  Widget entries(List<Expense> items) => items.isEmpty
      ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
          child: Text('Nothing logged yet. Start with your next expense.',
              style: type(13, color: secondaryText)))
      : Column(children: [
          for (final e in items.reversed)
            Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: hairline))),
                child: Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: panel(radius: 12),
                      child: Center(
                          child: SourceIcon(iconFor(e.label),
                              size: 18, color: secondaryText))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(e.label, style: type(13, weight: FontWeight.w500)),
                        const SizedBox(height: 1),
                        Text(
                            '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}',
                            style: type(11, color: tertiaryText))
                      ])),
                  Text('−${e.amount} DZD',
                      style: type(13, weight: FontWeight.w600))
                ]))
        ]);

  String dateLabel(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Widget today() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (expired) ...[
          Text('Your budget period has ended.',
              style: type(15, color: caution)),
          FilledButton(
              onPressed: () => setState(() => renewing = true),
              child: const Text('Start new period')),
          const SizedBox(height: 16)
        ],
        Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(children: [
              Expanded(
                  child: Text(dateLabel(DateTime.now()),
                      style: type(13,
                          color: secondaryText, weight: FontWeight.w500))),
              for (var i = 0; i < 7; i++)
                Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == DateTime.now().weekday - 1
                            ? mint
                            : i < DateTime.now().weekday - 1
                                ? const Color(0x8034D399)
                                : surfaceHigh))
            ])),
        const SizedBox(height: 36),
        Text('$allowance',
            textAlign: TextAlign.center,
            style: type(88,
                    weight: FontWeight.w600,
                    spacing: -3.96,
                    height: 1,
                    color: allowance < 0 ? caution : mint)
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 8),
        Text('DZD today',
            textAlign: TextAlign.center,
            style: type(16, color: secondaryText, weight: FontWeight.w500)),
        const SizedBox(height: 10),
        Text('$remaining DZD left · $remainingDays days remaining',
            textAlign: TextAlign.center, style: type(11, color: tertiaryText)),
        const SizedBox(height: 24),
        GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 90,
            children: [
              for (final item in [
                ('Coffee', 50),
                ('Sandwich', 150),
                ('Bus', 30),
                ('Water', 30),
                ('Meal', 300)
              ])
                Semantics(
                    label: '${item.$1}, ${item.$2} DZD',
                    button: true,
                    child: Material(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                            onTap: saving || expired
                                ? null
                                : () => log(item.$1, item.$2),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 14, 8, 12),
                                child: Column(children: [
                                  SourceIcon(iconFor(item.$1), size: 24),
                                  const SizedBox(height: 6),
                                  Text('${item.$2} DZD',
                                      style: type(13,
                                          weight: FontWeight.w600, height: 1)),
                                  const SizedBox(height: 6),
                                  Text(item.$1,
                                      style: type(10,
                                          color: tertiaryText, height: 1))
                                ]))))),
              Material(
                  color: const Color(0x1F34D399),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0x3D34D399))),
                  child: InkWell(
                      onTap: saving || expired ? null : customExpense,
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SourceIcon('plus', color: mint),
                            const SizedBox(height: 6),
                            Text('Add',
                                style: type(10,
                                    color: mint, weight: FontWeight.w500))
                          ])))
            ]),
        if (saved > 0 || goalTarget > 0)
          Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                      onTap: saving ? null : editBudget,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: Text(
                                      goalName.isEmpty
                                          ? 'Your savings'
                                          : goalName,
                                      style:
                                          type(13, weight: FontWeight.w600))),
                              Text(
                                  goalTarget > 0
                                      ? '$saved / $goalTarget DZD'
                                      : '$saved DZD',
                                  style: type(11, color: tertiaryText))
                            ]),
                            if (goalTarget > 0) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                      value: (saved / goalTarget).clamp(0, 1),
                                      minHeight: 6,
                                      color: mint,
                                      backgroundColor: surfaceHigh,
                                      semanticsLabel: 'Savings goal progress'))
                            ]
                          ]))))),
        const SizedBox(height: 20),
        sectionLabel("Today's log"),
        entries(expenses
            .where((e) => DateUtils.isSameDay(e.date, DateTime.now()))
            .toList()),
      ]);

  Widget setting(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
              onTap: saving ? null : editBudget,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  child: Row(children: [
                    Expanded(
                        child: Text(label,
                            style: type(13, weight: FontWeight.w500))),
                    Text(value, style: type(11, color: tertiaryText)),
                    const SizedBox(width: 4),
                    const SourceIcon('chevron-right',
                        size: 14, color: tertiaryText)
                  ])))));

  Widget history() {
    final all = [...pastExpenses, ...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in all) {
      grouped
          .putIfAbsent(DateUtils.dateOnly(expense.date), () => [])
          .add(expense);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: Text('History',
              style: type(26, weight: FontWeight.w600, spacing: -.78))),
      if (all.isEmpty) entries([]),
      for (final day in grouped.entries) ...[
        Row(children: [
          Expanded(
              child: sectionLabel(DateUtils.isSameDay(day.key, DateTime.now())
                  ? 'Today'
                  : dateLabel(day.key))),
          Text('${day.value.fold<int>(0, (sum, e) => sum + e.amount)} DZD',
              style: type(11))
        ]),
        entries(day.value.reversed.toList()),
        const SizedBox(height: 20)
      ],
      Text('$spent DZD spent this period',
          style: type(11, color: tertiaryText)),
      const SizedBox(height: 24),
      const Divider(color: hairline, height: 1),
      const SizedBox(height: 20),
      sectionLabel('Settings'),
      setting(
          'Period',
          days == 30
              ? 'Monthly'
              : days == 7
                  ? 'Weekly'
                  : '$days days'),
      setting('Fixed costs', '$fixedCosts DZD'),
      setting('Savings goal', '$goalTarget DZD'),
      Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: panel(radius: 16),
          child: Row(children: [
            Expanded(child: Text('Language', style: type(13))),
            Text('English', style: type(11, color: tertiaryText))
          ])),
    ]);
  }

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
                                : Text(loadError!))
                        : budget == null || renewing
                            ? BudgetOnboarding(
                                initialDays: days,
                                renewing: renewing,
                                onSave: startPeriod,
                                onCancel: () =>
                                    setState(() => renewing = false))
                            : ListView(
                                key: ValueKey('$tab-$renewing'),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                children: [
                                    if (tab == 0)
                                      today()
                                    else if (tab == 1)
                                      PriceCheck(
                                          allowance: allowance,
                                          expired: expired,
                                          onBack: () => setState(() => tab = 0))
                                    else
                                      history()
                                  ])))),
        bottomNavigationBar: budget == null || renewing
            ? null
            : Container(
                decoration: const BoxDecoration(
                    color: background,
                    border: Border(top: BorderSide(color: hairline))),
                child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                      child: Row(children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => tab = i),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SourceIcon(['home', 'search', 'list'][i],
                                          size: 22,
                                          color:
                                              tab == i ? mint : tertiaryText),
                                      const SizedBox(height: 5),
                                      Text(['Today', 'Check', 'History'][i],
                                          style: type(10,
                                              weight: FontWeight.w500,
                                              color: tab == i
                                                  ? mint
                                                  : tertiaryText)),
                                    ]),
                              ),
                            ),
                          ),
                      ]),
                    )),
              ),
      );
}
