import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/models/loan.dart';
import '../../domain/rules/loan_reminders.dart';

class LoanNotifications {
  final openLoan = ValueNotifier<String?>(null);
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  Future<void> _queue = Future.value();
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> initialize() async {
    if (!supported) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    await plugin.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_notification'),
            iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false)),
        onDidReceiveNotificationResponse: (r) => openLoan.value = r.payload);
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      openLoan.value = launch!.notificationResponse?.payload;
    }
    ready = true;
  }

  Future<String?> sync(List<Loan> loans, bool request) {
    // Serialize scheduling so an older save cannot overwrite newer alarms.
    final work = _queue.then((_) => _sync(loans, request));
    _queue = work.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return work;
  }

  Future<String?> _sync(List<Loan> loans, bool request) async {
    if (!supported) return null;
    try {
      if (!ready) await initialize();
      tz.setLocalLocation(tz
          .getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (request) {
        await android?.requestNotificationsPermission();
        await ios?.requestPermissions(alert: true, badge: false, sound: true);
      }
      final allowed = await android?.areNotificationsEnabled() ??
          (await ios?.checkPermissions())?.isEnabled ??
          true;
      await plugin.cancelAll();
      if (!allowed) {
        return request
            ? 'Loan saved. Enable Waffir notifications in phone Settings to get reminders.'
            : null;
      }
      final prefs = await SharedPreferences.getInstance();
      final handled =
          (prefs.getStringList('loan_reminders_handled') ?? []).toSet();
      final now = DateTime.now();
      final reminders = loanReminders(loans, now, handled);
      const details = NotificationDetails(
          android: AndroidNotificationDetails(
              'loan_repayments', 'Loan repayments',
              channelDescription: 'Due and overdue loan reminders',
              importance: Importance.high,
              priority: Priority.high),
          iOS: DarwinNotificationDetails());
      // ponytail: keep the nearest 60 alerts within iOS's 64-request limit; refill on app resume.
      for (var i = 0; i < reminders.length && i < 60; i++) {
        final r = reminders[i];
        if (!r.when.isAfter(now)) {
          await plugin.show(
              id: i,
              title: 'Waffir - Loan repayment',
              body: r.body,
              notificationDetails: details,
              payload: r.loan.id);
          handled.add('immediate/${r.key}');
        } else {
          await plugin.zonedSchedule(
              id: i,
              title: 'Waffir - Loan repayment',
              body: r.body,
              scheduledDate: tz.TZDateTime(
                  tz.local, r.when.year, r.when.month, r.when.day, 12),
              notificationDetails: details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              payload: r.loan.id);
        }
        handled.add(r.key);
        if (!await prefs.setStringList(
            'loan_reminders_handled', handled.toList())) {
          throw StateError('Reminder state not saved');
        }
      }
      return null;
    } catch (error) {
      debugPrint('Loan reminder setup failed: $error');
      return 'Your loan is saved. Reminders could not be set. Open Loans to try again.';
    }
  }
}
