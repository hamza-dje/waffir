import 'package:flutter/material.dart';
import 'data/storage/preferences_budget_storage.dart';
import 'presentation/app.dart';
import 'data/notifications/loan_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = LoanNotifications();
  runApp(WafirApp(
      storage: const PreferencesBudgetStorage(),
      syncReminders: reminders.sync,
      loanOpen: reminders.openLoan));
}
