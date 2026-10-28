import 'package:flutter/material.dart';
import '../../domain/models/app_currency.dart';
export '../../domain/models/app_currency.dart';

class MoneyScope extends InheritedWidget {
  const MoneyScope({super.key, required this.currency, required super.child});
  final AppCurrency currency;
  static AppCurrency of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoneyScope>()?.currency ??
      AppCurrency.dzd;
  static AppCurrency read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MoneyScope>()?.currency ??
      AppCurrency.dzd;
  @override
  bool updateShouldNotify(MoneyScope oldWidget) =>
      currency != oldWidget.currency;
}
