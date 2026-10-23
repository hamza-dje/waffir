import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafir/data/notifications/loan_notifications.dart';
import 'package:wafir/domain/models/loan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'native reminder requests schedule, update, cancel and handle denied permission',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    final calls = <MethodCall>[];
    var allowed = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_timezone'), (_) async => 'Africa/Algiers');
    messenger.setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => true,
        'areNotificationsEnabled' => allowed,
        'requestNotificationsPermission' => allowed,
        'getNotificationAppLaunchDetails' => {'notificationLaunchedApp': false},
        _ => null
      };
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'), null);
      messenger.setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          null);
    });
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, now.day + 2);
    Loan loan({int paid = 0}) => Loan(
        id: 'l',
        person: 'Private name',
        amount: 500,
        lent: true,
        date: now,
        due: due,
        payments:
            paid == 0 ? [] : [LoanPayment(id: 'p', amount: paid, date: now)]);
    final adapter = LoanNotifications();
    expect(await adapter.sync([loan()], true), isNull);
    final scheduled = calls.where((c) => c.method == 'zonedSchedule').toList();
    expect(scheduled.length, 2);
    expect(scheduled.first.arguments['scheduledDateTime'], contains('12:00:00'));
    expect(scheduled.first.arguments['body'], contains('500 DA'));
    expect(scheduled.first.arguments['body'], isNot(contains('Private name')));
    expect(scheduled.first.arguments['payload'], 'l');
    calls.clear();
    expect(await adapter.sync([loan(paid: 200)], false), isNull);
    expect(
        calls.where((c) => c.method == 'zonedSchedule').first.arguments['body'],
        contains('300 DA'));
    calls.clear();
    await adapter.sync([loan(paid: 500)], false);
    expect(calls.any((c) => c.method == 'cancelAll'), true);
    expect(calls.any((c) => c.method == 'zonedSchedule'), false);
    calls.clear();
    allowed = false;
    expect(await adapter.sync([loan()], true), contains('Settings'));
    expect(calls.any((c) => c.method == 'zonedSchedule'), false);
  });
}
