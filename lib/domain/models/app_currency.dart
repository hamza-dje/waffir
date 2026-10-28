enum AppCurrency {
  dzd(1, 'DZD'),
  eur(100, 'EUR');

  const AppCurrency(this.scale, this.code);
  final int scale;
  final String code;
  String input(num minorUnits) => scale == 1
      ? (minorUnits == minorUnits.round()
          ? minorUnits.round().toString()
          : minorUnits.toStringAsFixed(2))
      : (minorUnits / scale).toStringAsFixed(2);
  static AppCurrency decode(Object? value) => value == 'EUR' ? eur : dzd;
}
