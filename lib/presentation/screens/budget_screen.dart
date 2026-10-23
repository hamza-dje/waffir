import '../widgets/app_navigation.dart';
import '../widgets/product_list.dart';
import '../design/format.dart';
import '../widgets/editor_actions.dart';
import '../widgets/expense_rows.dart';
import '../widgets/content_widgets.dart';
import 'loans_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/repositories/budget_storage.dart';
import '../controllers/budget_book.dart';
import '../design/design.dart';
import 'editors.dart';
import 'onboarding.dart';
import '../widgets/expense_sheet.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen(
      {super.key, required this.storage, this.syncReminders, this.loanOpen});
  final BudgetStorage storage;
  final ReminderSync? syncReminders;
  final ValueNotifier<String?>? loanOpen;
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with WidgetsBindingObserver {
  late final book = BudgetBook(widget.storage);
  BudgetData get data => book.data;
  bool get saving => book.saving;
  String? get loadError => book.loaded ? null : book.error;
  int tab = 0;
  bool creating = false;
  BudgetRecord? carrySource;
  Timer? dateTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    dateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    book.addListener(refresh);
    widget.loanOpen?.addListener(openNotification);
    book.load().then((ok) {
      if (mounted && ok) {
        setState(() => creating = data.budgets.isEmpty);
        widget.syncReminders?.call(data.loans, false);
        openNotification();
      }
    });
  }

  @override
  void dispose() {
    dateTimer?.cancel();
    widget.loanOpen?.removeListener(openNotification);
    book.removeListener(refresh);
    book.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      widget.syncReminders?.call(data.loans, false);
    }
  }

  void openNotification() {
    final id = widget.loanOpen?.value;
    if (!mounted || !book.loaded || id == null) return;
    widget.loanOpen?.value = null;
    setState(() => tab = 2);
    if (data.loans.any((l) => l.id == id)) {
      openLoan(context, book, id, widget.syncReminders);
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<bool> report(Future<bool> change) async {
    final ok = await change;
    if (!ok && mounted && book.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: CurrencyText(book.error!)));
    }
    return ok;
  }

  Future<void> log(String label, int amount, String icon,
      [DateTime? date]) async {
    await report(
        book.logExpense(Expense(label, amount, date ?? DateTime.now(), icon)));
  }

  Future<void> customExpense() async {
    final result = await showModalBottomSheet<Expense>(
        context: context,
        isScrollControlled: true,
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => ExpenseSheet(budget: data.active!));
    if (result != null && mounted) {
      await log(result.label, result.amount, result.icon, result.date);
    }
  }

  Future<bool> replaceBudget(BudgetRecord record) =>
      report(book.correctBudget(record));

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
    if (result == 'delete' || result is Expense) {
      await report(
          book.correctExpense(id, index, result is Expense ? result : null));
    }
  }

  Future<void> newBudget([BudgetRecord? source]) async {
    if (saving || data.active != null) return;
    int? choice;
    if (source != null && !source.legacy && book.cashBalance(source) > 0) {
      var selected = book.cashBalance(source);
      choice = await showDialog<int>(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, update) => AlertDialog(
                    title: const Text('Start a new budget'),
                    content: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CurrencyText(
                                  '${book.cashBalance(source)} DA is left in the saved budget.'),
                              const SizedBox(height: 16),
                              for (final value in [book.cashBalance(source), 0])
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            backgroundColor: selected == value
                                                ? const Color(0x2634D399)
                                                : surfaceHigh),
                                        onPressed: () =>
                                            update(() => selected = value),
                                        child: Row(children: [
                                          SourceIcon(
                                              selected == value
                                                  ? 'check'
                                                  : 'banknote',
                                              color: selected == value
                                                  ? mint
                                                  : secondaryText),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(value == 0
                                                  ? 'Enter new amount'
                                                  : 'Use remaining money')),
                                        ]))),
                            ])),
                    actions: [
                      DialogActions(
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () => Navigator.pop(context, selected),
                          confirmLabel: 'Continue')
                    ],
                  )));
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
    final ok = await report(book.startBudget(funds, start, end, products,
        carryFrom: carrySource?.id));
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
    if (await report(book.stopBudget(active.id)) && mounted) {
      await newBudget(data.budgets.firstWhere((b) => b.id == active.id));
    }
  }

  BudgetRecord? get lastSaved =>
      data.budgets.reversed.where((b) => b.closedAt != null).firstOrNull;
  Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      child: CurrencyText(label,
          style: type(26,
              role: TextRole.display, weight: FontWeight.w600, spacing: -.78)));
  Widget stat(String label, String value,
          {Color color = primaryText, Key? valueKey, double? labelHeight}) =>
      Container(
          padding: const EdgeInsets.all(14),
          decoration: panel(radius: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: labelHeight,
                child:
                    CurrencyText(label, style: type(11, color: secondaryText))),
            const SizedBox(height: 6),
            CurrencyText(value,
                key: valueKey,
                style: type(21,
                    role: TextRole.display,
                    color: color,
                    weight: FontWeight.w600))
          ]));
  Widget emptyHome() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading('Home'),
        const SizedBox(height: 36),
        const SourceIcon('banknote', size: 44, color: mint),
        const SizedBox(height: 24),
        CurrencyText('No active budget',
            textAlign: TextAlign.center,
            style: type(26, role: TextRole.display, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        CurrencyText('Your saved budgets and expenses are in History.',
            textAlign: TextAlign.center, style: type(13, color: secondaryText)),
        const SizedBox(height: 28),
        FilledButton(
            onPressed: saving ? null : () => newBudget(lastSaved),
            child: const CurrencyText('Start new budget')),
      ]);
  Widget home(BudgetRecord b) {
    final f = BudgetFigures(b, DateTime.now(), loans: data.loans);
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
      Container(
          key: const ValueKey('today-section'),
          padding: const EdgeInsets.all(20),
          decoration: panel(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FittedBox(
                fit: BoxFit.scaleDown,
                child: CurrencyText(
                    f.leftToday == null ? '—' : '${money(f.leftToday!)} DA',
                    key: const ValueKey('left-today'),
                    style: type(72,
                            role: TextRole.display,
                            weight: FontWeight.w600,
                            spacing: -3.6,
                            height: 1,
                            color: (f.leftToday ?? 0) < 0 ? caution : mint)
                        .copyWith(fontFeatures: const [
                      FontFeature.tabularFigures()
                    ]))),
            if (usable && f.leftToday! <= 0)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CurrencyText('Stop for today',
                      textAlign: TextAlign.center,
                      style:
                          type(14, color: caution, weight: FontWeight.w600))),
            const SizedBox(height: 8),
            CurrencyText('Left today',
                textAlign: TextAlign.center,
                style: type(16, color: secondaryText, weight: FontWeight.w500)),
            const SizedBox(height: 10),
            CurrencyText('${f.cash} DA cash left in this budget',
                textAlign: TextAlign.center,
                style: type(11, color: tertiaryText)),
            if (f.todayLimit != null && f.leftToday! > f.cash) ...[
              const SizedBox(height: 12),
              Text('Part of this amount depends on repayment.',
                  textAlign: TextAlign.center, style: type(12, color: caution)),
            ],
            if (f.transfers.expected > 0 || f.transfers.reserved > 0) ...[
              const SizedBox(height: 8),
              CurrencyText(
                  '${f.transfers.expected} DA expected back - ${f.transfers.reserved} DA reserved for repayment',
                  textAlign: TextAlign.center,
                  style: type(11, color: secondaryText)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
                onPressed: !usable || saving ? null : customExpense,
                icon: const SourceIcon('plus', color: Color(0xFF06251A)),
                label: const Text('Add expense')),
          ])),
      const SizedBox(height: 16),
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
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: stat(
                'Daily average from tomorrow',
                f.upcoming == null
                    ? (future ? 'Not started' : 'No days remaining')
                    : '${money(f.upcoming!)} DA',
                valueKey: const ValueKey('upcoming-average'),
                labelHeight: MediaQuery.textScalerOf(context).scale(30))),
        const SizedBox(width: 8),
        Expanded(
            child: stat(
                'Tomorrow’s limit',
                f.tomorrowLimit == null
                    ? (future ? 'Not started' : 'No days remaining')
                    : '${money(f.tomorrowLimit!)} DA',
                valueKey: const ValueKey('tomorrow-limit'),
                labelHeight: MediaQuery.textScalerOf(context).scale(30),
                color: (f.tomorrowLimit ?? 0) < 0 ? caution : primaryText)),
      ]),
      const SizedBox(height: 6),
      CurrencyText('Estimates. Update with today’s spending.',
          style: type(11, color: tertiaryText)),
      const SizedBox(height: 24),
      if (data.loans.any((l) => l.remaining > 0)) ...[
        TapCard(
            onTap: () => setState(() => tab = 2),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Loans',
                                style: type(15, weight: FontWeight.w600))),
                        const SourceIcon('chevron-right',
                            size: 16, color: secondaryText)
                      ]),
                      const SizedBox(height: 12),
                      CurrencyText(
                          '${data.loans.where((l) => l.lent).fold<int>(0, (s, l) => s + l.remaining)} DA owed to me',
                          style: type(14, color: mint)),
                      const SizedBox(height: 6),
                      CurrencyText(
                          '${data.loans.where((l) => !l.lent).fold<int>(0, (s, l) => s + l.remaining)} DA I owe',
                          style: type(14, color: caution)),
                      const SizedBox(height: 8),
                      Text(nearestLoan(),
                          style: type(11, color: secondaryText)),
                    ]))),
        const SizedBox(height: 24),
      ],
      if (data.products.isNotEmpty) sectionLabel('Usual expenses'),
      if (data.products.isNotEmpty)
        GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 100 * MediaQuery.textScalerOf(context).scale(1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final p in data.products)
                TapCard(
                    onTap: !usable || saving
                        ? null
                        : () => log(p.name, p.price, p.icon),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                        child: Column(children: [
                          Opacity(
                              opacity: .55,
                              child: SourceIcon(p.icon, size: 24)),
                          const SizedBox(height: 6),
                          CurrencyText('${p.price} DA',
                              style: type(13, weight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          CurrencyText(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: type(10, color: tertiaryText))
                        ]))),
            ]),
      const SizedBox(height: 24),
      sectionLabel("Today's log"),
      ExpenseRows(
          budget: b,
          onlyToday: true,
          onEdit: (index) => editExpense(b.id, index)),
    ]);
  }

  String nearestLoan() {
    final dated = data.loans
        .where((l) => l.remaining > 0 && l.due != null)
        .toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));
    return dated.isEmpty
        ? 'No due dates'
        : '${loanStatus(dated.first)} - ${dateText(dated.first.due!)}';
  }

  Widget history() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading('History'),
        if (data.budgets.isEmpty)
          CurrencyText('No budgets saved yet.',
              style: type(13, color: secondaryText)),
        for (final b in data.budgets.reversed)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                  color: b.closedAt == null ? const Color(0x2634D399) : surface,
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
                          style: type(15,
                              weight: FontWeight.w600,
                              color: b.closedAt == null ? mint : primaryText)),
                      subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: CurrencyText(
                              '${dateText(b.start)} – ${dateText(b.end)}\n${b.legacy ? 'Original budget unavailable' : '${b.funds} DA budget · ${book.cashBalance(b)} DA left'}',
                              style: type(11, color: secondaryText))),
                      trailing: SourceIcon('chevron-right',
                          size: 16,
                          color: b.closedAt == null ? mint : tertiaryText),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) => BudgetHistoryPage(
                                  cash: () => book.cashBalance(data.budgets
                                      .firstWhere((r) => r.id == b.id)),
                                  getRecord: () => data.budgets.firstWhere((r) => r.id == b.id),
                                  transfer: () => data.budgets.where((r) => r.carriedFrom == b.id).fold<int>(0, (sum, r) => sum + r.carriedAmount),
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
                    Row(children: [
                      Expanded(
                          child: CurrencyText('${b.funds} DA',
                              style: type(28,
                                  role: TextRole.display,
                                  weight: FontWeight.w600))),
                      Text('${b.days} days',
                          style: type(13, color: secondaryText))
                    ]),
                    const SizedBox(height: 6),
                    CurrencyText('${dateText(b.start)} – ${dateText(b.end)}',
                        style: type(12, color: secondaryText)),
                    const SizedBox(height: 8),
                    CurrencyText('${book.cashBalance(b)} DA left',
                        style: type(13, color: secondaryText)),
                    if (b.carriedFrom != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CurrencyText(
                              '${b.carriedAmount} DA carried from a saved budget.',
                              style: type(11, color: tertiaryText))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              style: editAction(),
                              onPressed: saving ? null : () => editBudget(b.id),
                              child: const CurrencyText('Edit',
                                  textAlign: TextAlign.center))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0x1FF5B84A)),
                              onPressed: saving ? null : stopBudget,
                              child: CurrencyText('Stop and Save',
                                  textAlign: TextAlign.center,
                                  style: type(16,
                                      color: caution,
                                      weight: FontWeight.w500)))),
                    ]),
                  ])),
        ] else
          FilledButton(
              onPressed: saving ? null : () => newBudget(lastSaved),
              child: const CurrencyText('Start new budget')),
        const SizedBox(height: 24),
        sectionLabel('Usual products'),
        ProductList(
            onEdit: (product) => editProduct(context, product),
            products: data.products,
            enabled: !saving,
            onChanged: (products) => report(book.setProducts(products))),
      ]);
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: !book.loaded
                      ? Center(
                          child: loadError == null
                              ? const CircularProgressIndicator()
                              : Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: CurrencyText(loadError!)))
                      : creating
                          ? BudgetOnboarding(
                              initialFunds: carrySource == null
                                  ? null
                                  : book.cashBalance(carrySource!),
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
                                  else if (tab == 2)
                                    LoansScreen(
                                        book: book,
                                        syncReminders: widget.syncReminders)
                                  else
                                    budgetPage()
                                ])))),
      bottomNavigationBar: !book.loaded || creating
          ? null
          : AppNavigation(
              selected: tab, onSelect: (value) => setState(() => tab = value)));
}

class BudgetHistoryPage extends StatefulWidget {
  const BudgetHistoryPage(
      {super.key,
      required this.getRecord,
      required this.onEditBudget,
      required this.onEditExpense,
      required this.transfer,
      this.cash});
  final BudgetRecord Function() getRecord;
  final int Function() transfer;
  final int Function()? cash;
  final Future<void> Function() onEditBudget;
  final Future<void> Function(int) onEditExpense;
  @override
  State<BudgetHistoryPage> createState() => _BudgetHistoryPageState();
}

class _BudgetHistoryPageState extends State<BudgetHistoryPage> {
  String query = '';
  Widget summaryCard(String label, String amount,
          [String? detail, Color color = primaryText]) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: panel(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: type(12, color: secondaryText)),
            const SizedBox(height: 8),
            CurrencyText(amount,
                style: type(22,
                    role: TextRole.display,
                    weight: FontWeight.w600,
                    color: color)),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(detail, style: type(11, color: secondaryText))
            ]
          ]));
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
          summaryCard(
              'Total budget', b.legacy ? 'Unavailable' : '${b.funds} DA'),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: summaryCard(
                    'Left',
                    b.legacy
                        ? 'Unavailable'
                        : '${widget.cash?.call() ?? b.balance} DA',
                    '${BudgetFigures(b, b.closedAt ?? DateTime.now()).remainingDays} days left',
                    mint)),
            const SizedBox(width: 8),
            Expanded(
                child: summaryCard(
                    'Spent',
                    '${b.spent} DA',
                    '${BudgetFigures(b, b.closedAt ?? DateTime.now()).completed} completed days',
                    caution)),
          ]),
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
          FilledButton(
              style: editAction(),
              onPressed: () async {
                await widget.onEditBudget();
                if (mounted) setState(() {});
              },
              child: const CurrencyText('Edit budget')),
          const SizedBox(height: 20),
          sectionLabel('Expenses'),
          SearchInput(
              hint: 'Search expense names',
              hintColor: secondaryText,
              onChanged: (value) => setState(() => query = value)),
          const SizedBox(height: 12),
          ExpenseRows(
              budget: b,
              query: query,
              onEdit: (i) async {
                await widget.onEditExpense(i);
                if (mounted) setState(() {});
              }),
        ]));
  }
}
