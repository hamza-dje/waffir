import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/models/spending_plan.dart';
import '../../domain/rules/expense_rules.dart';
import '../controllers/budget_book.dart';
import '../design/design.dart';
import '../design/format.dart';
import '../widgets/content_widgets.dart';
import '../widgets/editor_actions.dart';
import '../widgets/form_controls.dart';
import 'editors.dart';

Future<void> showPlanSheet(BuildContext context, BudgetBook book,
    [SpendingPlan? initial]) async {
  if (book.data.active == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start a budget before adding a plan.')));
    return;
  }
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => PlanSheet(book: book, initial: initial));
}

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.book});
  final BudgetBook book;
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int filter = 0;
  String query = '';
  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final now = DateTime.now();
    final items = book.data.plans.where((p) {
      final budget = book.data.budgets.firstWhere((b) => b.id == p.budgetId);
      final review = p.needsReview(now, budget);
      return p.label.toLowerCase().contains(query.toLowerCase()) &&
          (filter == 2
              ? p.complete
              : !p.complete && (filter == 1 ? review : !review));
    }).toList()
      ..sort((a, b) => a.days.first.date.compareTo(b.days.first.date));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageHeading(title: 'Plan'),
      const SizedBox(height: spaceTight),
      Text('Set money aside for the days that matter.',
          style: type(13, color: secondaryText)),
      const SizedBox(height: spaceSection),
      FilledButton.icon(
          onPressed: book.saving ? null : () => showPlanSheet(context, book),
          icon: const SourceIcon('plus', color: ink),
          label: const Text('Add plan')),
      const SizedBox(height: spaceSection),
      SearchInput(
          hint: 'Search plans', onChanged: (v) => setState(() => query = v)),
      const SizedBox(height: spaceRelated),
      AppFilters(
          labels: ['Upcoming', 'Needs review', 'Completed'],
          selected: filter,
          onChanged: (value) => setState(() => filter = value)),
      const SizedBox(height: spaceSection),
      if (items.isEmpty)
        Text(
            filter == 0
                ? 'Plan your next expense. Its money stays reserved until you record or cancel it.'
                : 'No plans here.',
            style: type(13, color: secondaryText, height: 1.5)),
      for (final p in items)
        Padding(
            padding: const EdgeInsets.only(bottom: spaceRelated),
            child: TapCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => PlanDetails(book: book, id: p.id))),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      SourceIcon(p.icon,
                          color: p.complete ? secondaryText : mint),
                      const SizedBox(width: listItemGap),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(p.label,
                                style: type(15, weight: FontWeight.w600)),
                            const SizedBox(height: spaceTight),
                            Text(
                                '${dateText(p.days.first.date)}${p.days.length > 1 ? ' + ${p.days.length - 1} days' : ''}',
                                style: type(11, color: secondaryText)),
                            const SizedBox(height: 4),
                            Text(
                                '${p.days.where((d) => !d.pending).length}/${p.days.length} resolved',
                                style: type(11, color: tertiaryText))
                          ])),
                      CurrencyText('${p.reserved} DA',
                          style:
                              type(18, color: mint, weight: FontWeight.w600)),
                      const SizedBox(width: spaceTight),
                      const SourceIcon('chevron-right',
                          size: 16, color: tertiaryText)
                    ]))))
    ]);
  }
}

class PlanDetails extends StatelessWidget {
  const PlanDetails({super.key, required this.book, required this.id});
  final BudgetBook book;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: book,
      builder: (context, _) {
        final p = book.data.plans.where((p) => p.id == id).firstOrNull;
        if (p == null) {
          return Scaffold(
              appBar: editorBar(context, 'Plan'),
              body: const Center(child: Text('Plan removed.')));
        }
        final budget = book.data.budgets.firstWhere((b) => b.id == p.budgetId);
        final closed = budget.closedAt != null;
        return Scaffold(
            appBar: editorBar(context, p.label),
            body: ListView(padding: const EdgeInsets.all(pageInset), children: [
              SurfaceCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text('Reserved', style: type(13, color: secondaryText)),
                    const SizedBox(height: spaceTight),
                    CurrencyText('${p.reserved} DA',
                        style: type(36,
                            color: mint,
                            role: TextRole.display,
                            weight: FontWeight.w600)),
                    DetailField(
                        label: 'Budget',
                        value:
                            '${dateText(budget.start)} - ${dateText(budget.end)}'),
                    DetailField(
                        label: 'Amount mode',
                        value: ['Total', 'Per day', 'Custom'][p.mode.index]),
                    if (closed && !p.complete)
                      Text(
                          'Budget stopped. Move unfinished days to the active budget or cancel them.',
                          style: type(13, color: caution)),
                  ])),
              const SizedBox(height: spaceRelated),
              FilledButton(
                  style: editAction(),
                  onPressed: book.saving || p.complete
                      ? null
                      : () => showPlanSheet(context, book, p),
                  child: const Text('Edit')),
              const SizedBox(height: spaceSection),
              sectionLabel('Planned days'),
              for (final d in p.days)
                Padding(
                    padding: const EdgeInsets.only(bottom: spaceRelated),
                    child: SurfaceCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Row(children: [
                            Expanded(
                                child: Text(dateText(d.date), style: type(14))),
                            CurrencyText('${d.amount} DA',
                                style: type(18, weight: FontWeight.w600))
                          ]),
                          const SizedBox(height: spaceTight),
                          Text(
                              d.cancelled
                                  ? 'Cancelled'
                                  : d.expenseId != null
                                      ? 'Recorded in History'
                                      : closed ||
                                              daysBetween(
                                                      d.date, DateTime.now()) >
                                                  0
                                          ? 'Needs review'
                                          : daysBetween(
                                                      d.date, DateTime.now()) ==
                                                  0
                                              ? 'Due today'
                                              : 'Reserved',
                              style: type(12,
                                  color: d.pending &&
                                          p.needsReview(DateTime.now(), budget)
                                      ? caution
                                      : secondaryText)),
                          if (d.expenseId != null) ...[
                            DetailField(
                                label: 'Actual expense',
                                value:
                                    '${budget.expenses.firstWhere((e) => e.id == d.expenseId).amount} DA'),
                            const SizedBox(height: spaceRelated),
                            FilledButton(
                                style: editAction(),
                                onPressed: book.saving
                                    ? null
                                    : () async {
                                        final index = budget.expenses
                                            .indexWhere(
                                                (e) => e.id == d.expenseId);
                                        if (index < 0) return;
                                        final result = await Navigator.push<
                                                Object>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => ExpenseEditor(
                                                    expense:
                                                        budget.expenses[index],
                                                    budget: budget)));
                                        if (result == null) return;
                                        await book.correctExpense(
                                            budget.id,
                                            index,
                                            result is Expense ? result : null);
                                        if (context.mounted &&
                                            book.error != null) {
                                          planError(context, book.error!);
                                        }
                                      },
                                child: const Text('Edit expense')),
                          ],
                          if (d.pending) ...[
                            const SizedBox(height: spaceRelated),
                            if (!closed &&
                                daysBetween(DateTime.now(), d.date) <= 0) ...[
                              FilledButton(
                                  onPressed: book.saving
                                      ? null
                                      : () async {
                                          final expense =
                                              await Navigator.push<Expense>(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          ExpenseEditor(
                                                              expense: Expense(
                                                                  p.label,
                                                                  d.amount,
                                                                  d.date,
                                                                  p.icon),
                                                              budget: budget,
                                                              recording:
                                                                  true)));
                                          if (expense != null) {
                                            await book.recordPlanDay(
                                                p.id, d.id, expense);
                                            if (context.mounted &&
                                                book.error != null) {
                                              planError(context, book.error!);
                                            }
                                          }
                                        },
                                  child: const Text('Record expense')),
                              const SizedBox(height: spaceTight),
                            ],
                            FilledButton(
                                style: deleteAction(),
                                onPressed: book.saving
                                    ? null
                                    : () async {
                                        if (await confirmAction(
                                            context,
                                            'Cancel planned day?',
                                            'Release this day\'s reservation.',
                                            'Cancel day')) {
                                          await book.cancelPlanDay(p.id, d.id);
                                        }
                                      },
                                child: const Text('Cancel day')),
                          ]
                        ]))),
              const SizedBox(height: spaceSection),
              FilledButton(
                  style: deleteAction(),
                  onPressed: book.saving
                      ? null
                      : () async {
                          if (await confirmAction(
                              context,
                              'Delete plan?',
                              'Release unfinished reservations. Recorded expenses stay in History.',
                              'Delete')) {
                            final ok = await book.deletePlan(p.id);
                            if (ok && context.mounted) Navigator.pop(context);
                          }
                        },
                  child: const Text('Delete plan')),
            ]));
      });
}

void planError(BuildContext context, String error) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));

class PlanSheet extends StatefulWidget {
  const PlanSheet({super.key, required this.book, this.initial});
  final BudgetBook book;
  final SpendingPlan? initial;
  @override
  State<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<PlanSheet> {
  final label = TextEditingController();
  String amount = '', icon = 'banknote';
  PlanAmountMode mode = PlanAmountMode.total;
  bool get perDay => mode == PlanAmountMode.perDay;
  bool get custom => mode == PlanAmountMode.custom;
  bool details = false, busy = false;
  String? error;
  late String budgetId;
  late final String id =
      widget.initial?.id ?? 'plan-${DateTime.now().microsecondsSinceEpoch}';
  final List<DateTime> dates = [];
  final Map<DateTime, int> dayAmounts = {};
  List<PlanDay> get resolved => widget.initial?.budgetId == budgetId
      ? widget.initial!.days.where((d) => !d.pending).toList()
      : [];
  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    budgetId = p?.budgetId ?? widget.book.data.active!.id;
    if (p != null) {
      label.text = p.label;
      icon = p.icon;
      mode = p.mode;
      final pending = p.days.where((d) => d.pending).toList();
      dates.addAll(pending.map((d) => d.date));
      if (custom) {
        dayAmounts.addEntries(pending.map((d) => MapEntry(d.date, d.amount)));
      }
      amount =
          (perDay && pending.isNotEmpty ? pending.first.amount : p.reserved)
              .toString();
    }
  }

  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  SpendingPlan draft() {
    final split =
        SpendingPlan.split(dates, moneyValue(amount) ?? 0, perDay, '$id-edit');
    return SpendingPlan(
        id: id,
        budgetId: budgetId,
        label: label.text.trim(),
        icon: icon,
        mode: mode,
        days: [
          ...resolved,
          for (var i = 0; i < split.length; i++)
            PlanDay(
                id: widget.initial?.days
                        .where((d) => d.pending && d.date == split[i].date)
                        .firstOrNull
                        ?.id ??
                    '$id-${split[i].date.toIso8601String()}',
                date: split[i].date,
                amount:
                    dayAmounts[split[i].date] ?? (custom ? 0 : split[i].amount))
        ]..sort((a, b) => a.date.compareTo(b.date)));
  }

  Future<void> addDate() async {
    final budget = widget.book.data.budgets.firstWhere((b) => b.id == budgetId);
    final today = dayOnly(DateTime.now());
    final first = budget.start.isAfter(today) ? budget.start : today;
    if (first.isAfter(budget.end)) {
      setState(() => error = 'Choose a budget with future dates.');
      return;
    }
    final picked = await showDatePicker(
        context: context,
        initialDate: first,
        firstDate: first,
        lastDate: budget.end);
    if (picked != null &&
        !dates.contains(dayOnly(picked)) &&
        !resolved.any((d) => d.date == dayOnly(picked))) {
      setState(() {
        dates.add(dayOnly(picked));
        dates.sort();
        error = null;
      });
      if (custom && mounted) {
        await changeAmount(PlanDay(id: '', date: dayOnly(picked), amount: 0));
      }
    }
  }

  Future<void> changeDate(PlanDay day) async {
    final budget = widget.book.data.budgets.firstWhere((b) => b.id == budgetId);
    final today = dayOnly(DateTime.now());
    final first = budget.start.isAfter(today) ? budget.start : today;
    if (first.isAfter(budget.end)) {
      setState(() => error = 'Move this plan to an active budget first.');
      return;
    }
    final picked = await showDatePicker(
        context: context,
        initialDate: day.date.isBefore(first) ? first : day.date,
        firstDate: first,
        lastDate: budget.end);
    if (picked == null || !mounted || picked == day.date) return;
    if (dates.contains(picked) || resolved.any((d) => d.date == picked)) {
      setState(() => error = 'This date is already in the plan.');
      return;
    }
    setState(() {
      dates.remove(day.date);
      dates.add(picked);
      dates.sort();
      dayAmounts.remove(day.date);
      dayAmounts[picked] = day.amount;
      error = null;
    });
  }

  Future<void> changeAmount(PlanDay day) async {
    final value = await showAmountDialog(context, day.amount);
    if (value == null || !mounted) return;
    setState(() {
      for (final d in draft().days.where((d) => d.pending)) {
        dayAmounts[d.date] = d.amount;
      }
      dayAmounts[day.date] = value;
      mode = PlanAmountMode.custom;
      amount =
          dates.fold<int>(0, (s, d) => s + (dayAmounts[d] ?? 0)).toString();
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final plan = draft();
    final budget = book.data.budgets.firstWhere((b) => b.id == budgetId);
    final preview =
        BudgetFigures(budget, DateTime.now(), loans: book.data.loans, plans: [
      for (final p in book.data.plans)
        if (p.id != id) p,
      plan
    ]);
    final shortfall =
        preview.cash - preview.transfers.reserved - preview.plannedReserved;
    return FormSheet(
        title: widget.initial == null ? 'Add plan' : 'Edit plan',
        onBack: details && !busy ? () => setState(() => details = false) : null,
        children: [
          if (!details) ...[
            Row(children: [
              for (final value in PlanAmountMode.values) ...[
                if (value.index > 0) const SizedBox(width: spaceTight),
                Expanded(
                    child: FilledButton(
                        style: compactAction(cancel: mode != value),
                        onPressed: () => setState(() {
                              mode = value;
                              dayAmounts.clear();
                            }),
                        child:
                            Text(['Total', 'Per day', 'Custom'][value.index])))
              ]
            ]),
            const SizedBox(height: spaceRelated),
            if (custom)
              Text(
                  'Choose dates next, then enter an estimated amount for each day.',
                  style: type(14, color: secondaryText, height: 1.5)),
            if (!custom)
              FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CurrencyText('${amount.isEmpty ? '0' : amount} DA',
                      style: type(52,
                          role: TextRole.display, weight: FontWeight.w600))),
            const SizedBox(height: spaceRelated),
            if (!custom)
              AmountKeypad(
                  keyHeight: 52,
                  onKey: (key) => setState(() {
                        amount = amountKey(amount, key);
                        dayAmounts.clear();
                        error = null;
                      })),
          ] else ...[
            LabeledField(
                label: 'Plan label',
                controller: label,
                hintText: 'e.g. Books for class',
                maxLength: 60),
            const SizedBox(height: spaceRelated),
            ExpenseIcons(icon, (v) => setState(() => icon = v)),
            const SizedBox(height: spaceSection),
            if (budget.closedAt != null && book.data.active != null) ...[
              FilledButton(
                  style: secondaryAction(),
                  onPressed: () => setState(() {
                        budgetId = book.data.active!.id;
                        dates.clear();
                      }),
                  child: const Text('Move to active budget')),
              const SizedBox(height: spaceRelated),
            ],
            const FormLabel('Planned dates'),
            const SizedBox(height: spaceTight),
            for (final d in plan.days)
              Padding(
                  padding: const EdgeInsets.only(bottom: spaceTight),
                  child: Row(children: [
                    Expanded(
                        child: PickerButton(
                            text: dateText(d.date),
                            icon: 'calendar',
                            onPressed:
                                d.pending && !busy ? () => changeDate(d) : null,
                            trailing: TextButton(
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize:
                                        const Size(48, compactActionHeight),
                                    foregroundColor: primaryText),
                                onPressed: d.pending && !busy
                                    ? () => changeAmount(d)
                                    : null,
                                child: CurrencyText('${d.amount} DA',
                                    style: buttonType(16))))),
                    if (d.pending) ...[
                      const SizedBox(width: spaceTight),
                      AppActionIcon(
                          icon: 'trash',
                          tooltip: 'Remove date',
                          destructive: true,
                          onPressed: busy
                              ? null
                              : () => setState(() => dates.remove(d.date))),
                    ]
                  ])),
            FilledButton.icon(
                style: secondaryAction(),
                onPressed: busy ? null : addDate,
                icon: const SourceIcon('calendar'),
                label: const Text('Add day')),
            const SizedBox(height: spaceSection),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: AmountStatCard(
                      label: 'Reserved after saving',
                      value: '${preview.plannedReserved} DA',
                      backgroundColor: surfaceHigh,
                      labelHeight: MediaQuery.textScalerOf(context).scale(30),
                      color: caution)),
              const SizedBox(width: spaceTight),
              Expanded(
                  child: AmountStatCard(
                      label: "Today's ordinary limit",
                      value: preview.todayLimit == null
                          ? 'Not active'
                          : '${money(preview.todayLimit!)} DA',
                      labelHeight: MediaQuery.textScalerOf(context).scale(30),
                      backgroundColor: surfaceHigh)),
            ]),
            const SizedBox(height: spaceTight),
            Text('Planned money is separate from Left today.',
                style: type(12, color: secondaryText)),
            if (shortfall < 0)
              CurrencyText('${-shortfall} DA shortfall',
                  style: type(13, color: caution)),
          ],
          if (error != null)
            Padding(
                padding: const EdgeInsets.only(top: spaceRelated),
                child: Text(error!, style: type(13, color: danger))),
          const SizedBox(height: spaceSection),
          FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final invalid = custom ? null : positiveMoney(amount);
                      if (invalid != null) {
                        setState(() => error = invalid);
                        return;
                      }
                      if (!details) {
                        setState(() {
                          if (!custom) amount = moneyValue(amount).toString();
                          details = true;
                        });
                        return;
                      }
                      final invalidPlan = plan.validate(budget);
                      if (invalidPlan != null) {
                        setState(() => error = invalidPlan);
                        return;
                      }
                      if (shortfall < 0 &&
                          !await confirmAction(
                              context,
                              'Reservation exceeds available cash',
                              '${-shortfall} DA is not covered. Save this plan anyway?',
                              'Save plan')) {
                        return;
                      }
                      if (!context.mounted) return;
                      setState(() => busy = true);
                      final ok = await book.savePlan(plan);
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          busy = false;
                          error = book.error;
                        });
                      }
                    },
              child: Text(details ? 'Save plan' : 'Continue')),
        ]);
  }
}
