import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_data.dart';
import 'design.dart';
import 'editors.dart';
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
              textStyle: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
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
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  backgroundColor: surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)))),
        ),
        home: const BudgetScreen(),
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
  BudgetData data = BudgetData();
  int tab = 0;
  bool saving = false, creating = false;
  BudgetRecord? carrySource;
  String? loadError;
  Timer? dateTimer;
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
      final raw =
          store.getString('budget_state_v2') ?? store.getString('budget_state');
      final loaded = raw == null ? BudgetData() : BudgetData.decode(raw);
      if (loaded.budgets.where((b) => b.closedAt == null).length > 1 ||
          loaded.budgets.any((b) => b.validate() != null) ||
          loaded.products.any((p) =>
              p.name.trim().isEmpty || p.price <= 0 || p.price > 999999999)) {
        throw const FormatException('Invalid budget data');
      }
      if (mounted) {
        setState(() {
          prefs = store;
          data = loaded;
          creating = loaded.budgets.isEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => loadError =
            'Could not load your budget. Restart the app. Your saved data has not been changed.');
      }
    }
  }

  Future<bool> save(BudgetData next) async {
    if (saving) return false;
    setState(() => saving = true);
    try {
      if (!await prefs!.setString('budget_state_v2', next.encode())) {
        throw StateError('Save failed');
      }
      if (mounted) setState(() => data = next);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: CurrencyText('Could not save. Please try again.')));
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> log(String label, int amount, String icon) async {
    final active = data.active;
    if (active == null || !active.canLog(DateTime.now()) || saving) return;
    await save(data.replace(active.copyWith(expenses: [
      ...active.expenses,
      Expense(label, amount, DateTime.now(), icon)
    ])));
  }

  Future<void> customExpense() async {
    final result = await showModalBottomSheet<(String, int)>(
        context: context,
        isScrollControlled: true,
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => const ExpenseSheet());
    if (result != null && mounted) await log(result.$1, result.$2, 'banknote');
  }

  Future<bool> replaceBudget(BudgetRecord record) async {
    final error = record.validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: CurrencyText(error)));
      return false;
    }
    return save(data.replace(record));
  }

  Future<void> editBudget(String id) async {
    final record = data.budgets.firstWhere((b) => b.id == id);
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) =>
                BudgetEditor(initial: record, onSave: replaceBudget)));
  }

  Future<void> editExpense(String id, int index) async {
    if (saving) return;
    final record = data.budgets.firstWhere((b) => b.id == id);
    final result = await Navigator.push<Object>(
        context,
        MaterialPageRoute(
            builder: (_) => ExpenseEditor(
                expense: record.expenses[index], budget: record)));
    if (result == null || !mounted) return;
    final items = [...record.expenses];
    if (result == 'delete') {
      items.removeAt(index);
    } else if (result is Expense) {
      items[index] = result;
    } else {
      return;
    }
    await replaceBudget(record.copyWith(expenses: items));
  }

  Future<void> newBudget([BudgetRecord? source]) async {
    if (saving || data.active != null) return;
    int? choice;
    if (source != null && !source.legacy && source.balance > 0) {
      choice = await showDialog<int>(
          context: context,
          builder: (context) => AlertDialog(
                  backgroundColor: surface,
                  title: const CurrencyText('Start a new budget'),
                  content: CurrencyText(
                      '${source.balance} DA is left in the saved budget.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const CurrencyText('Later')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, 0),
                        child: const CurrencyText('Enter new amount')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, source.balance),
                        child: const CurrencyText('Use remaining money'))
                  ]));
      if (choice == null) return;
    }
    if (mounted) {
      setState(() {
        carrySource = choice != null && choice > 0 ? source : null;
        creating = true;
      });
    }
  }

  Future<bool> startBudget(int funds, DateTime start, DateTime end,
      List<UsualProduct> products) async {
    if (data.active != null) return false;
    final useCarry = carrySource != null && carrySource!.balance == funds;
    final record = BudgetRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        funds: funds,
        start: start,
        end: end,
        carriedFrom: useCarry ? carrySource!.id : null,
        carriedAmount: useCarry ? funds : 0);
    final error = record.validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: CurrencyText(error)));
      return false;
    }
    final ok = await save(
        BudgetData(budgets: [...data.budgets, record], products: products));
    if (ok && mounted) {
      setState(() {
        creating = false;
        carrySource = null;
        tab = 0;
      });
    }
    return ok;
  }

  Future<void> stopBudget() async {
    final active = data.active;
    if (active == null || saving) return;
    final yes = await confirmAction(
        context,
        'Stop and save budget?',
        'Keep this budget in History. No more expenses can be added to it. You can still correct its entries.',
        'Stop and save');
    if (!yes || !mounted) return;
    final closed = active.copyWith(closedAt: DateTime.now());
    if (await replaceBudget(closed) && mounted) await newBudget(closed);
  }

  BudgetRecord? get lastSaved =>
      data.budgets.reversed.where((b) => b.closedAt != null).firstOrNull;
  Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      child: CurrencyText(label,
          style: type(26, weight: FontWeight.w600, spacing: -.78)));
  Widget stat(String label, String value, {Color color = primaryText}) =>
      Container(
          padding: const EdgeInsets.all(14),
          decoration: panel(radius: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CurrencyText(label, style: type(11, color: secondaryText)),
            const SizedBox(height: 6),
            CurrencyText(value,
                style: type(21, color: color, weight: FontWeight.w600))
          ]));
  Widget emptyHome() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading('Home'),
        const SizedBox(height: 36),
        const SourceIcon('banknote', size: 44, color: mint),
        const SizedBox(height: 24),
        CurrencyText('No active budget',
            textAlign: TextAlign.center,
            style: type(26, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        CurrencyText('Your saved budgets and expenses are in History.',
            textAlign: TextAlign.center, style: type(13, color: secondaryText)),
        const SizedBox(height: 28),
        FilledButton(
            onPressed: saving ? null : () => newBudget(lastSaved),
            child: const CurrencyText('Start new budget')),
      ]);
  Widget home(BudgetRecord b) {
    final f = BudgetFigures(b, DateTime.now());
    final usable = b.canLog(DateTime.now());
    final future = daysBetween(DateTime.now(), b.start) > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(children: [
            Expanded(
                child: CurrencyText(dateText(DateTime.now()),
                    style: type(13,
                        color: secondaryText, weight: FontWeight.w500))),
            CurrencyText('${f.remainingDays} days left',
                style: type(11, color: tertiaryText))
          ])),
      const SizedBox(height: 30),
      if (!usable) ...[
        CurrencyText(
            future
                ? 'Budget starts ${dateText(b.start)}'
                : 'Your budget period has ended.',
            textAlign: TextAlign.center,
            style: type(15, color: caution)),
        const SizedBox(height: 16)
      ],
      FittedBox(
          fit: BoxFit.scaleDown,
          child: CurrencyText(f.leftToday == null ? '—' : money(f.leftToday!),
              key: const ValueKey('left-today'),
              style: type(80,
                      weight: FontWeight.w600,
                      spacing: -3.6,
                      height: 1,
                      color: (f.leftToday ?? 0) < 0 ? caution : mint)
                  .copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()]))),
      const SizedBox(height: 8),
      CurrencyText('DA left today',
          textAlign: TextAlign.center,
          style: type(16, color: secondaryText, weight: FontWeight.w500)),
      const SizedBox(height: 10),
      CurrencyText('${b.balance} DA left in this budget',
          textAlign: TextAlign.center, style: type(11, color: tertiaryText)),
      if (usable && f.leftToday! <= 0)
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CurrencyText('Stop for today',
                textAlign: TextAlign.center,
                style: type(14, color: caution, weight: FontWeight.w600))),
      const SizedBox(height: 24),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: stat('Original daily average', '${money(f.original)} DA',
                color: mint)),
        const SizedBox(width: 8),
        Expanded(
            child: stat("Today's limit",
                f.todayLimit == null ? '—' : '${money(f.todayLimit!)} DA'))
      ]),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: stat('Spent today', '${f.spentToday} DA')),
        const SizedBox(width: 8),
        Expanded(
            child: stat(f.savings < 0 ? 'Over budget so far' : 'Saved so far',
                '${money(f.savings.abs())} DA',
                color: f.savings < 0 ? caution : primaryText))
      ]),
      const SizedBox(height: 8),
      Container(
          padding: const EdgeInsets.all(14),
          decoration: panel(radius: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CurrencyText('Daily average from tomorrow',
                style: type(11, color: secondaryText)),
            const SizedBox(height: 6),
            CurrencyText(
                f.upcoming == null
                    ? (future ? 'Not started' : 'No days remaining')
                    : '${money(f.upcoming!)} DA',
                key: const ValueKey('upcoming-average'),
                style: type(21, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            CurrencyText('Estimate. Updates with today’s spending.',
                style: type(11, color: tertiaryText))
          ])),
      const SizedBox(height: 24),
      sectionLabel('Usual expenses'),
      if (data.products.isEmpty)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton(
                onPressed: () => setState(() => tab = 2),
                child: const CurrencyText(
                    'Set up your usual products in Budget'))),
      GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 100,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final p in data.products)
              Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                      onTap: !usable || saving
                          ? null
                          : () => log(p.name, p.price, p.icon),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                          child: Column(children: [
                            SourceIcon(p.icon, size: 24),
                            const SizedBox(height: 6),
                            CurrencyText('${p.price}',
                                style: type(13, weight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            CurrencyText(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: type(10, color: tertiaryText))
                          ])))),
            Material(
                color: const Color(0x1F34D399),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none),
                child: InkWell(
                    onTap: !usable || saving ? null : customExpense,
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SourceIcon('plus', color: mint),
                          const SizedBox(height: 6),
                          CurrencyText('Add', style: type(11, color: mint))
                        ])))
          ]),
      const SizedBox(height: 24),
      sectionLabel("Today's log"),
      ExpenseRows(
          budget: b,
          onlyToday: true,
          onEdit: (index) => editExpense(b.id, index)),
    ]);
  }

  Widget
      history() =>
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            heading('History'),
            if (data.budgets.isEmpty)
              CurrencyText('No budgets saved yet.',
                  style: type(13, color: secondaryText)),
            for (final b in data.budgets.reversed)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          leading: SourceIcon(b.closedAt == null ? 'banknote' : 'list',
                              color: b.closedAt == null ? mint : secondaryText),
                          title: CurrencyText(
                              b.legacy
                                  ? 'Earlier expenses'
                                  : b.closedAt == null
                                      ? 'Active budget'
                                      : 'Saved budget',
                              style: type(15, weight: FontWeight.w600)),
                          subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: CurrencyText(
                                  '${dateText(b.start)} – ${dateText(b.end)}\n${b.legacy ? 'Original budget unavailable' : '${b.funds} DA budget · ${b.balance} DA left'}',
                                  style: type(11, color: secondaryText))),
                          trailing: const SourceIcon('chevron-right',
                              size: 16, color: tertiaryText),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => BudgetHistoryPage(
                                      getRecord: () => data.budgets
                                          .firstWhere((r) => r.id == b.id),
                                      transfer: () =>
                                          data.budgets.where((r) => r.carriedFrom == b.id).fold<int>(0, (sum, r) => sum + r.carriedAmount),
                                      onEditBudget: () => editBudget(b.id),
                                      onEditExpense: (i) => editExpense(b.id, i))))))),
          ]);
  Widget budgetPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading('Budget'),
        if (data.active case final b?) ...[
          Container(
              padding: const EdgeInsets.all(18),
              decoration: panel(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CurrencyText('${b.funds} DA',
                        style: type(28, weight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    CurrencyText(
                        '${dateText(b.start)} – ${dateText(b.end)} · ${b.days} days',
                        style: type(12, color: secondaryText)),
                    const SizedBox(height: 8),
                    CurrencyText('${b.balance} DA left',
                        style: type(13, color: secondaryText)),
                    if (b.carriedFrom != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CurrencyText(
                              '${b.carriedAmount} DA carried from a saved budget.',
                              style: type(11, color: tertiaryText))),
                    const SizedBox(height: 16),
                    OutlinedButton(
                        onPressed: saving ? null : () => editBudget(b.id),
                        child: const CurrencyText('Edit budget')),
                    TextButton(
                        onPressed: saving ? null : stopBudget,
                        child: CurrencyText('Stop and save budget',
                            style: type(14, color: caution))),
                  ])),
        ] else
          FilledButton(
              onPressed: saving ? null : () => newBudget(lastSaved),
              child: const CurrencyText('Start new budget')),
        const SizedBox(height: 24),
        sectionLabel('Usual products'),
        ProductList(
            products: data.products,
            enabled: !saving,
            onChanged: (products) =>
                save(BudgetData(budgets: data.budgets, products: products))),
      ]);
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
                              : Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CurrencyText(loadError!)))
                      : creating
                          ? BudgetOnboarding(
                              initialFunds: carrySource?.balance,
                              products: data.products,
                              onSave: startBudget,
                              onCancel: () => setState(() {
                                    creating = false;
                                    carrySource = null;
                                  }))
                          : ListView(
                              key: ValueKey(tab),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              children: [
                                  if (tab == 0)
                                    data.active == null
                                        ? emptyHome()
                                        : home(data.active!)
                                  else if (tab == 1)
                                    history()
                                  else
                                    budgetPage()
                                ])))),
      bottomNavigationBar: prefs == null || creating
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: background,
              ),
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
                                            SourceIcon(
                                                ['home', 'list', 'banknote'][i],
                                                size: 22,
                                                color: tab == i
                                                    ? mint
                                                    : tertiaryText),
                                            const SizedBox(height: 5),
                                            CurrencyText(
                                                [
                                                  'Home',
                                                  'History',
                                                  'Budget'
                                                ][i],
                                                style: type(10,
                                                    weight: FontWeight.w500,
                                                    color: tab == i
                                                        ? mint
                                                        : tertiaryText))
                                          ]))))
                      ])))));
}

class ExpenseRows extends StatelessWidget {
  const ExpenseRows(
      {super.key,
      required this.budget,
      required this.onEdit,
      this.onlyToday = false});
  final BudgetRecord budget;
  final ValueChanged<int> onEdit;
  final bool onlyToday;
  @override
  Widget build(BuildContext context) {
    final indexed = budget.expenses
        .asMap()
        .entries
        .where(
            (e) => !onlyToday || daysBetween(e.value.date, DateTime.now()) == 0)
        .toList()
      ..sort((a, b) => b.value.date.compareTo(a.value.date));
    final groups = <DateTime, List<MapEntry<int, Expense>>>{};
    for (final e in indexed) {
      groups.putIfAbsent(dayOnly(e.value.date), () => []).add(e);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (indexed.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
            child: CurrencyText('No expenses yet.',
                style: type(13, color: secondaryText))),
      for (final group in groups.entries) ...[
        if (!onlyToday)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(children: [
                Expanded(child: sectionLabel(dateText(group.key))),
                CurrencyText(
                    '${group.value.fold<int>(0, (sum, e) => sum + e.value.amount)} DA',
                    style: type(11))
              ])),
        for (final entry in group.value)
          InkWell(
              onTap: () => onEdit(entry.key),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: const BoxDecoration(),
                  child: Row(children: [
                    Container(
                        width: 36,
                        height: 36,
                        decoration: panel(radius: 12),
                        child: Center(
                            child: SourceIcon(entry.value.icon,
                                size: 18, color: secondaryText))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          CurrencyText(entry.value.label,
                              style: type(13, weight: FontWeight.w500)),
                          const SizedBox(height: 1),
                          CurrencyText(
                              '${entry.value.date.hour.toString().padLeft(2, '0')}:${entry.value.date.minute.toString().padLeft(2, '0')} · tap to edit',
                              style: type(11, color: tertiaryText))
                        ])),
                    CurrencyText('−${entry.value.amount}',
                        style: type(13, weight: FontWeight.w600))
                  ]))),
      ],
    ]);
  }
}

class BudgetHistoryPage extends StatefulWidget {
  const BudgetHistoryPage(
      {super.key,
      required this.getRecord,
      required this.onEditBudget,
      required this.onEditExpense,
      required this.transfer});
  final BudgetRecord Function() getRecord;
  final int Function() transfer;
  final Future<void> Function() onEditBudget;
  final Future<void> Function(int) onEditExpense;
  @override
  State<BudgetHistoryPage> createState() => _BudgetHistoryPageState();
}

class _BudgetHistoryPageState extends State<BudgetHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final b = widget.getRecord();
    final transfer = widget.transfer();
    return Scaffold(
        appBar: editorBar(
            context, b.closedAt == null ? 'Active budget' : 'Saved budget'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          CurrencyText('${dateText(b.start)} – ${dateText(b.end)}',
              style: type(13, color: secondaryText)),
          const SizedBox(height: 12),
          CurrencyText(
              b.legacy
                  ? 'Original budget unavailable'
                  : '${b.funds} DA budget · ${b.balance} DA left',
              style: type(20, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          CurrencyText('${b.spent} DA spent',
              style: type(13, color: secondaryText)),
          if (b.closedAt != null)
            CurrencyText('Saved ${dateText(b.closedAt!)}',
                style: type(11, color: tertiaryText)),
          if (transfer > 0)
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CurrencyText(
                    '$transfer DA carried to the next budget. This transfer stays fixed after corrections.',
                    style: type(12, color: secondaryText))),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: () async {
                await widget.onEditBudget();
                if (mounted) setState(() {});
              },
              child: const CurrencyText('Edit budget')),
          const SizedBox(height: 20),
          sectionLabel('Expenses'),
          ExpenseRows(
              budget: b,
              onEdit: (i) async {
                await widget.onEditExpense(i);
                if (mounted) setState(() {});
              }),
        ]));
  }
}
