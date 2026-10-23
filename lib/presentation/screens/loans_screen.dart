import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../../domain/models/loan.dart';
import '../../domain/rules/expense_rules.dart';
import '../controllers/budget_book.dart';
import '../design/design.dart';
import 'editors.dart';
import 'onboarding.dart' show AmountKeypad;

typedef ReminderSync = Future<String?> Function(List<Loan> loans, bool request);

String loanStatus(Loan l) {
  if (l.remaining == 0) return 'Paid';
  if (l.due == null) return 'No due date';
  final days = daysBetween(DateTime.now(), l.due!);
  return days == 0
      ? 'Due today'
      : days < 0
          ? '${-days} days overdue'
          : '$days days left';
}

Widget loanPanel(Widget child, {Color color = surface}) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(16), child: child));

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, required this.book, this.syncReminders});
  final BudgetBook book;
  final ReminderSync? syncReminders;
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  int filter = 0;
  String query = '';
  @override
  Widget build(BuildContext context) {
    final all = widget.book.data.loans;
    final items = all
        .where((l) =>
            (filter == 3 ? l.remaining == 0 : l.remaining > 0) &&
            (filter != 1 || l.lent) &&
            (filter != 2 || !l.lent) &&
            '${l.person} ${l.note}'.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final overdue = (b.overdue(DateTime.now()) ? 1 : 0) -
            (a.overdue(DateTime.now()) ? 1 : 0);
        return overdue != 0
            ? overdue
            : (a.due ?? DateTime(9999)).compareTo(b.due ?? DateTime(9999));
      });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Loans',
          style: type(26, role: TextRole.display, weight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Know what is owed. Keep your budget clear.',
          style: type(13, color: secondaryText)),
      const SizedBox(height: 24),
      Row(children: [
        for (final lent in [true, false]) ...[
          if (!lent) const SizedBox(width: 8),
          Expanded(
              child: loanPanel(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(lent ? 'Owed to me' : 'I owe',
                    style: type(12, color: secondaryText)),
                const SizedBox(height: 8),
                CurrencyText(
                    '${all.where((l) => l.lent == lent).fold<int>(0, (s, l) => s + l.remaining)} DA',
                    style: type(25,
                        role: TextRole.display,
                        color: lent ? mint : caution,
                        weight: FontWeight.w600))
              ])))
        ]
      ]),
      const SizedBox(height: 24),
      FilledButton.icon(
          onPressed: widget.book.saving
              ? null
              : () => showLoanSheet(context, widget.book,
                  syncReminders: widget.syncReminders),
          icon: const SourceIcon('plus', color: ink),
          label: const Text('Add loan')),
      const SizedBox(height: 24),
      TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: InputDecoration(
              hintText: 'Search people or notes',
              hintStyle: type(14, color: tertiaryText),
              prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: SourceIcon('search', color: secondaryText)))),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < 4; i++)
          ChoiceChip(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              label: Text(['All', 'Owed to me', 'I owe', 'Paid'][i]),
              selected: filter == i,
              onSelected: (_) => setState(() => filter = i),
              showCheckmark: false,
              side: BorderSide.none,
              selectedColor: const Color(0x2634D399),
              backgroundColor: surface,
              labelStyle: type(12, color: filter == i ? mint : secondaryText))
      ]),
      const SizedBox(height: 16),
      if (items.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
                all.isEmpty
                    ? 'Keep track of money you lend and borrow.'
                    : 'No matching loans.',
                textAlign: TextAlign.center,
                style: type(14, color: secondaryText))),
      for (final l in items)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TapCard(
                onTap: () =>
                    openLoan(context, widget.book, l.id, widget.syncReminders),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: SourceIcon('banknote',
                              color: l.lent ? mint : caution)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(l.person,
                                style: type(15, weight: FontWeight.w600)),
                            const SizedBox(height: 5),
                            Text(
                                '${l.lent ? 'Owed to me' : 'I owe'} - ${loanStatus(l)}',
                                style: type(11,
                                    color: l.overdue(DateTime.now())
                                        ? caution
                                        : secondaryText))
                          ])),
                      const SizedBox(width: 8),
                      CurrencyText('${l.remaining} DA',
                          style: type(18,
                              color: l.lent ? mint : caution,
                              weight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      const SourceIcon('chevron-right',
                          size: 14, color: tertiaryText)
                    ]))))
    ]);
  }
}

Future<void> openLoan(
        BuildContext context, BudgetBook book, String id, ReminderSync? sync) =>
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) =>
                LoanDetails(book: book, id: id, syncReminders: sync)));

class LoanDetails extends StatelessWidget {
  const LoanDetails(
      {super.key, required this.book, required this.id, this.syncReminders});
  final BudgetBook book;
  final String id;
  final ReminderSync? syncReminders;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: book,
      builder: (context, _) {
        final l = book.data.loans.where((l) => l.id == id).firstOrNull;
        if (l == null) {
          return Scaffold(
              appBar: editorBar(context, 'Loan'),
              body: const Center(child: Text('Loan removed.')));
        }
        final payments = [...l.payments]
          ..sort((a, b) => b.date.compareTo(a.date));
        return Scaffold(
            appBar: editorBar(context, l.person),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              loanPanel(Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.lent ? 'Owed to me' : 'I owe',
                        textAlign: TextAlign.center,
                        style: type(13, color: secondaryText)),
                    const SizedBox(height: 12),
                    CurrencyText('${l.remaining} DA',
                        textAlign: TextAlign.center,
                        style: type(48,
                            role: TextRole.display,
                            weight: FontWeight.w600,
                            color: l.lent ? mint : caution)),
                    const SizedBox(height: 8),
                    Text(loanStatus(l),
                        textAlign: TextAlign.center,
                        style: type(13,
                            color: l.overdue(DateTime.now())
                                ? caution
                                : secondaryText)),
                    const SizedBox(height: 24),
                    if (l.remaining > 0)
                      FilledButton(
                          onPressed: book.saving
                              ? null
                              : () => showPaymentSheet(context, book, l,
                                  syncReminders: syncReminders),
                          child: const Text('Record repayment')),
                    const SizedBox(height: 8),
                    FilledButton(
                        style: editAction(),
                        onPressed: book.saving
                            ? null
                            : () => showLoanSheet(context, book,
                                initial: l, syncReminders: syncReminders),
                        child: const Text('Edit'))
                  ])),
              const SizedBox(height: 16),
              loanPanel(Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sectionLabel('Loan details'),
                    loanDetailRow('Original amount', '${l.amount} DA'),
                    loanDetailRow('Loan date', dateText(l.date)),
                    loanDetailRow('Due date',
                        l.due == null ? 'No due date' : dateText(l.due!)),
                    loanDetailRow('Budget', budgetLabel(book, l.budgetId)),
                    if (l.note.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      sectionLabel('Note'),
                      Text(l.note, style: type(14, height: 1.5)),
                      const SizedBox(height: 8),
                    ],
                    if (l.due != null)
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Reminders at noon', style: type(13)),
                          subtitle: Text('Due day and the next day if unpaid',
                              style: type(11, color: secondaryText)),
                          value: l.remind,
                          onChanged: book.saving
                              ? null
                              : (v) async {
                                  final next = Loan(
                                      id: l.id,
                                      person: l.person,
                                      amount: l.amount,
                                      lent: l.lent,
                                      date: l.date,
                                      due: l.due,
                                      budgetId: l.budgetId,
                                      note: l.note,
                                      remind: v,
                                      payments: l.payments);
                                  if (await book.saveLoan(next) &&
                                      context.mounted) {
                                    await syncLoanReminders(
                                        context, book, syncReminders,
                                        request: v);
                                  }
                                })
                  ])),
              const SizedBox(height: 24),
              sectionLabel('Payment history'),
              if (payments.isEmpty)
                Text('No payments yet.', style: type(13, color: secondaryText)),
              for (final p in payments)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TapCard(
                        onTap: () => showPaymentSheet(context, book, l,
                            initial: p, syncReminders: syncReminders),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(dateText(p.date), style: type(14)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${TimeOfDay.fromDateTime(p.date).format(context)} - ${budgetLabel(book, p.budgetId)}',
                                        style: type(11, color: secondaryText))
                                  ])),
                              CurrencyText('${p.amount} DA',
                                  style: type(18, weight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const SourceIcon('chevron-right',
                                  size: 14, color: tertiaryText)
                            ]))))
            ]));
      });
}

Widget loanDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          flex: 4, child: Text(label, style: type(13, color: secondaryText))),
      const SizedBox(width: 12),
      Expanded(
          flex: 6,
          child: CurrencyText(value,
              textAlign: TextAlign.right,
              style: type(14, weight: FontWeight.w500))),
    ]));

String budgetLabel(BudgetBook book, String? id) {
  final b = book.data.budgets.where((b) => b.id == id).firstOrNull;
  return b == null
      ? 'Outside a budget'
      : '${b.closedAt == null ? 'Active' : 'Saved'} budget - ${dateText(b.start)}';
}

Future<void> syncLoanReminders(
    BuildContext context, BudgetBook book, ReminderSync? sync,
    {bool request = false}) async {
  final message = await sync?.call(book.data.loans, request);
  if (message != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> showLoanSheet(BuildContext context, BudgetBook book,
        {Loan? initial, ReminderSync? syncReminders}) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => LoanSheet(
            book: book, initial: initial, syncReminders: syncReminders));

class LoanSheet extends StatefulWidget {
  const LoanSheet(
      {super.key, required this.book, this.initial, this.syncReminders});
  final BudgetBook book;
  final Loan? initial;
  final ReminderSync? syncReminders;
  @override
  State<LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends State<LoanSheet> {
  late final amount =
      TextEditingController(text: widget.initial?.amount.toString() ?? '');
  late final person = TextEditingController(text: widget.initial?.person ?? '');
  late final note = TextEditingController(text: widget.initial?.note ?? '');
  late bool lent = widget.initial?.lent ?? true,
      details = widget.initial != null,
      remind = widget.initial?.remind ?? true;
  late DateTime date = widget.initial?.date ?? DateTime.now();
  DateTime? due;
  String? budgetId, error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    amount.addListener(updatePreview);
    due = widget.initial?.due;
    budgetId = widget.initial == null
        ? matchingBudget(widget.book, date)
        : widget.initial!.budgetId;
  }

  void updatePreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    amount.dispose();
    person.dispose();
    note.dispose();
    super.dispose();
  }

  Loan draft() => Loan(
      id: widget.initial?.id ?? 'loan-${DateTime.now().microsecondsSinceEpoch}',
      person: person.text.trim(),
      amount: int.tryParse(amount.text) ?? 0,
      lent: lent,
      date: date,
      due: due,
      budgetId: budgetId,
      note: note.text.trim(),
      remind: remind,
      payments: widget.initial?.payments ?? []);
  @override
  Widget build(BuildContext context) =>
      sheetFrame(context, widget.initial == null ? 'Add loan' : 'Edit loan', [
        if (details)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: () => setState(() => details = false),
                  icon: const SourceIcon('arrow-left', size: 16),
                  label: const Text('Amount and direction'))),
        if (!details) ...[
          Row(children: [
            for (final value in [true, false]) ...[
              if (!value) const SizedBox(width: 8),
              Expanded(
                  child: Semantics(
                selected: lent == value,
                child: FilledButton(
                    onPressed: widget.initial?.payments.isNotEmpty == true
                        ? null
                        : () => setState(() => lent = value),
                    style: compactAction().copyWith(
                        backgroundColor: WidgetStatePropertyAll(lent == value
                            ? const Color(0x2634D399)
                            : Colors.transparent),
                        foregroundColor: WidgetStatePropertyAll(
                            lent == value ? mint : secondaryText)),
                    child: Text(value ? 'I lent money' : 'I borrowed money',
                        textAlign: TextAlign.center)),
              ))
            ]
          ]),
          const SizedBox(height: 20),
          CurrencyText('${amount.text.isEmpty ? '0' : amount.text} DA',
              textAlign: TextAlign.center,
              style: type(52, role: TextRole.display, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          AmountKeypad(
              keyHeight: 52,
              onKey: (key) {
                error = null;
                if (key == '⌫') {
                  if (amount.text.isNotEmpty) {
                    amount.text =
                        amount.text.substring(0, amount.text.length - 1);
                  }
                } else if (amount.text.length < 9 && key != '.') {
                  amount.text += key;
                }
              }),
        ] else ...[
          CurrencyText('${amount.text} DA',
              textAlign: TextAlign.center,
              style: type(42,
                  role: TextRole.display,
                  weight: FontWeight.w600,
                  color: lent ? mint : caution)),
          const SizedBox(height: 16),
          loanField('Person', person, 'e.g. Amine', maxLength: 60),
          const SizedBox(height: 16),
          DateControl(
              'Loan date',
              date,
              (v) => setState(() {
                    date = DateTime(
                        v.year, v.month, v.day, date.hour, date.minute);
                    budgetId = matchingBudget(widget.book, date);
                  }),
              last: dayOnly(DateTime.now())),
          ExpenseTime(
              TimeOfDay.fromDateTime(date),
              (v) => setState(() => date =
                  DateTime(date.year, date.month, date.day, v.hour, v.minute))),
          const SizedBox(height: 16),
          if (due == null)
            OutlinedButton.icon(
                onPressed: () async {
                  final v = await showDatePicker(
                      context: context,
                      initialDate: dayOnly(date),
                      firstDate: dayOnly(date),
                      lastDate: DateTime(2100));
                  if (v != null) setState(() => due = v);
                },
                icon: const SourceIcon('calendar', color: secondaryText),
                label: const Text('Add due date (optional)'))
          else ...[
            DateControl(
                'Expected repayment date', due!, (v) => setState(() => due = v),
                first: dayOnly(date)),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => setState(() => due = null),
                    child: const Text('No due date')))
          ],
          const SizedBox(height: 16),
          loanField('Note (optional)', note, 'e.g. Books for this semester',
              maxLength: 240),
          if (due != null)
            SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Reminders at noon', style: type(13)),
                subtitle: Text('Amount only. No person name.',
                    style: type(11, color: secondaryText)),
                value: remind,
                onChanged: (v) => setState(() => remind = v)),
          BudgetLink(
              book: widget.book,
              date: date,
              value: budgetId,
              onChanged: (v) => setState(() => budgetId = v)),
          const SizedBox(height: 12),
          TransferPreview(book: widget.book, loan: draft()),
        ],
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: type(13, color: danger))),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (positiveMoney(amount.text) != null) {
                      setState(() => error = positiveMoney(amount.text));
                      return;
                    }
                    if (!details) {
                      setState(() {
                        details = true;
                        error = null;
                      });
                      return;
                    }
                    final loan = draft();
                    final invalid = loan.validate(DateTime.now());
                    if (invalid != null) {
                      setState(() => error = invalid);
                      return;
                    }
                    if (!await confirmShortfall(context, widget.book, loan)) {
                      return;
                    }
                    setState(() => busy = true);
                    final ok = await widget.book.saveLoan(loan);
                    if (!context.mounted) return;
                    if (!ok) {
                      setState(() {
                        busy = false;
                        error = widget.book.error;
                      });
                      return;
                    }
                    await syncLoanReminders(
                        context, widget.book, widget.syncReminders,
                        request: loan.remind && loan.due != null);
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(
                details ? (busy ? 'Saving...' : 'Save loan') : 'Continue')),
        if (widget.initial != null) ...[
          const SizedBox(height: 12),
          FilledButton(
              style: deleteAction(),
              onPressed: busy
                  ? null
                  : () async {
                      if (widget.initial!.payments.isNotEmpty) {
                        setState(
                            () => error = 'Delete the payment records first.');
                        return;
                      }
                      if (!await confirmAction(
                          context,
                          'Delete loan?',
                          'This also removes its budget cash movement.',
                          'Delete')) {
                        return;
                      }
                      if (await widget.book.deleteLoan(widget.initial!.id) &&
                          context.mounted) {
                        await syncLoanReminders(
                            context, widget.book, widget.syncReminders);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
              child: const Text('Delete loan'))
        ]
      ]);
}

Widget sheetFrame(BuildContext context, String title, List<Widget> children) =>
    SafeArea(
        top: false,
        child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.fromLTRB(
                    24, 12, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              decoration:
                                  panel(radius: 2, color: tertiaryText))),
                      const SizedBox(height: 20),
                      Text(title,
                          style: type(22,
                              role: TextRole.display, weight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      ...children
                    ]))));
Widget loanField(String label, TextEditingController controller, String hint,
        {int? maxLength}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: type(13, color: secondaryText)),
      const SizedBox(height: 8),
      TextField(
          controller: controller,
          maxLength: maxLength,
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: type(14, color: tertiaryText),
              fillColor: surfaceHigh))
    ]);

String? matchingBudget(BudgetBook book, DateTime date) {
  final matches = book.data.budgets
      .where((b) =>
          daysBetween(b.start, date) >= 0 && daysBetween(date, b.end) >= 0)
      .toList();
  return matches.length == 1 ? matches.single.id : null;
}

class BudgetLink extends StatelessWidget {
  const BudgetLink(
      {super.key,
      required this.book,
      required this.date,
      required this.value,
      required this.onChanged});
  final BudgetBook book;
  final DateTime date;
  final String? value;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) {
    final matches = book.data.budgets
        .where((b) =>
            b.id == value ||
            (daysBetween(b.start, date) >= 0 && daysBetween(date, b.end) >= 0))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Budget', style: type(13, color: secondaryText)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
          key: ValueKey(value),
          icon: const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                  child: SourceIcon('chevron-right',
                      size: 16, color: tertiaryText))),
          initialValue: value ?? '',
          isExpanded: true,
          style: type(16),
          decoration: const InputDecoration(
              fillColor: surfaceHigh, contentPadding: EdgeInsets.all(16)),
          items: [
            const DropdownMenuItem(value: '', child: Text('Outside a budget')),
            for (final b in matches)
              DropdownMenuItem(
                  value: b.id,
                  child: Text(budgetLabel(book, b.id),
                      overflow: TextOverflow.ellipsis))
          ],
          onChanged: (v) => onChanged(v == '' ? null : v))
    ]);
  }
}

class TransferPreview extends StatelessWidget {
  const TransferPreview({super.key, required this.book, required this.loan});
  final BudgetBook book;
  final Loan loan;
  @override
  Widget build(BuildContext context) {
    final b = book.data.budgets.where((b) => b.id == loan.budgetId).firstOrNull;
    if (b == null) {
      return Text('Saved outside a budget. No budget figures will change.',
          style: type(12, color: secondaryText));
    }
    final loans = [
      for (final l in book.data.loans)
        if (l.id != loan.id) l,
      loan
    ];
    final f = BudgetFigures(b, DateTime.now(), loans: loans);
    return loanPanel(
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CurrencyText('Cash after this transfer: ${f.cash} DA',
              style: type(13)),
          const SizedBox(height: 8),
          CurrencyText(
              "Today's limit after this transfer: ${f.todayLimit == null ? 'Outside current period' : '${money(f.todayLimit!)} DA'}",
              style: type(12, color: secondaryText)),
          if (f.cash < 0) ...[
            const SizedBox(height: 8),
            Text('This transfer exceeds available cash.',
                style: type(12, color: danger))
          ]
        ]),
        color: surfaceHigh);
  }
}

Future<bool> confirmShortfall(
    BuildContext context, BudgetBook book, Loan loan) async {
  final b = book.data.budgets.where((b) => b.id == loan.budgetId).firstOrNull;
  if (b == null) return true;
  final loans = [
    for (final l in book.data.loans)
      if (l.id != loan.id) l,
    loan
  ];
  if (BudgetFigures(b, DateTime.now(), loans: loans).cash >= 0) return true;
  return confirmAction(
      context,
      'Cash shortfall',
      'This transfer exceeds the cash in this budget. Save the money already handed over?',
      'Save anyway');
}

Future<void> showPaymentSheet(BuildContext context, BudgetBook book, Loan loan,
        {LoanPayment? initial, ReminderSync? syncReminders}) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => PaymentSheet(
            book: book,
            loanId: loan.id,
            initial: initial,
            syncReminders: syncReminders));

class PaymentSheet extends StatefulWidget {
  const PaymentSheet(
      {super.key,
      required this.book,
      required this.loanId,
      this.initial,
      this.syncReminders});
  final BudgetBook book;
  final String loanId;
  final LoanPayment? initial;
  final ReminderSync? syncReminders;
  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  Loan get loan =>
      widget.book.data.loans.firstWhere((l) => l.id == widget.loanId);
  late final amount = TextEditingController(
      text: '${widget.initial?.amount ?? loan.remaining}');
  late DateTime date = widget.initial?.date ?? DateTime.now();
  String? budgetId, error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    amount.addListener(updatePreview);
    budgetId = widget.initial == null
        ? matchingBudget(widget.book, date)
        : widget.initial!.budgetId;
  }

  void updatePreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  LoanPayment draft() => LoanPayment(
      id: widget.initial?.id ??
          'payment-${DateTime.now().microsecondsSinceEpoch}',
      amount: int.tryParse(amount.text) ?? 0,
      date: date,
      budgetId: budgetId);
  Loan preview() => loan.withPayments([
        for (final p in loan.payments)
          if (p.id != widget.initial?.id) p,
        draft()
      ]);
  @override
  Widget build(BuildContext context) => sheetFrame(context,
          widget.initial == null ? 'Record repayment' : 'Edit payment', [
        CurrencyText('${loan.remaining} DA remaining',
            style: type(15, color: loan.lent ? mint : caution)),
        const SizedBox(height: 16),
        LabeledField(
            label: 'Payment amount', controller: amount, currency: true),
        const SizedBox(height: 16),
        DateControl(
            'Payment date',
            date,
            (v) => setState(() {
                  date =
                      DateTime(v.year, v.month, v.day, date.hour, date.minute);
                  budgetId = matchingBudget(widget.book, date);
                }),
            first: dayOnly(loan.date),
            last: dayOnly(DateTime.now())),
        ExpenseTime(
            TimeOfDay.fromDateTime(date),
            (v) => setState(() => date =
                DateTime(date.year, date.month, date.day, v.hour, v.minute))),
        const SizedBox(height: 16),
        BudgetLink(
            book: widget.book,
            date: date,
            value: budgetId,
            onChanged: (v) => setState(() => budgetId = v)),
        const SizedBox(height: 12),
        PaymentPreview(book: widget.book, loan: preview(), budgetId: budgetId),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: type(13, color: danger))),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: FilledButton(
                  style: compactAction(cancel: true),
                  onPressed: busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton(
                  style: compactAction(),
                  onPressed: busy
                      ? null
                      : () async {
                          final next = preview();
                          final invalid = next.validate(DateTime.now());
                          if (invalid != null) {
                            setState(() => error = invalid);
                            return;
                          }
                          final b = widget.book.data.budgets
                              .where((b) => b.id == budgetId)
                              .firstOrNull;
                          final cash = b == null
                              ? 0
                              : BudgetFigures(b, DateTime.now(), loans: [
                                  for (final l in widget.book.data.loans)
                                    l.id == next.id ? next : l
                                ]).cash;
                          if (cash < 0 &&
                              context.mounted &&
                              !await confirmAction(
                                  context,
                                  'Cash shortfall',
                                  'This payment exceeds available cash. Record it anyway?',
                                  'Save anyway')) {
                            return;
                          }
                          setState(() => busy = true);
                          final ok =
                              await widget.book.savePayment(loan.id, draft());
                          if (!context.mounted) return;
                          if (!ok) {
                            setState(() {
                              busy = false;
                              error = widget.book.error;
                            });
                            return;
                          }
                          await syncLoanReminders(
                              context, widget.book, widget.syncReminders);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payment saved')));
                          }
                        },
                  child: Text(busy ? 'Saving...' : 'Save payment')))
        ]),
        if (widget.initial != null) ...[
          const SizedBox(height: 12),
          FilledButton(
              style: deleteAction(),
              onPressed: busy
                  ? null
                  : () async {
                      if (!await confirmAction(
                          context,
                          'Delete payment?',
                          'The loan and budget totals will update.',
                          'Delete')) {
                        return;
                      }
                      if (await widget.book
                              .deletePayment(loan.id, widget.initial!.id) &&
                          context.mounted) {
                        await syncLoanReminders(
                            context, widget.book, widget.syncReminders);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
              child: const Text('Delete payment'))
        ]
      ]);
}

class PaymentPreview extends StatelessWidget {
  const PaymentPreview(
      {super.key,
      required this.book,
      required this.loan,
      required this.budgetId});
  final BudgetBook book;
  final Loan loan;
  final String? budgetId;
  @override
  Widget build(BuildContext context) {
    final b = book.data.budgets.where((b) => b.id == budgetId).firstOrNull;
    if (b == null) {
      return Text('No budget figures will change.',
          style: type(12, color: secondaryText));
    }
    final f = BudgetFigures(b, DateTime.now(),
        loans: [for (final l in book.data.loans) l.id == loan.id ? loan : l]);
    return loanPanel(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CurrencyText('Cash after this transfer: ${f.cash} DA',
              style: type(13)),
          const SizedBox(height: 8),
          CurrencyText(
              "Today's limit after this transfer: ${f.todayLimit == null ? 'Outside current period' : '${money(f.todayLimit!)} DA'}",
              style: type(12, color: secondaryText))
        ]),
        color: surfaceHigh);
  }
}
