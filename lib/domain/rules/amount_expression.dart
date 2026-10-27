/// Basic arithmetic with normal multiplication/division precedence.
/// Returns only positive whole dinars within the supported money range.
int? moneyValue(String? input) {
  final text = (input ?? '')
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
  if (text.isEmpty || text.length > 80) return null;
  final tokens = RegExp(r'\d+(?:\.\d+)?|[+*/-]')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .toList();
  if (tokens.join() != text || tokens.length.isEven) return null;
  double sum = 0, term = 0;
  String operation = '+';
  for (var i = 0; i < tokens.length; i += 2) {
    final number = double.tryParse(tokens[i]);
    if (number == null || !number.isFinite) return null;
    switch (operation) {
      case '+':
        sum += term;
        term = number;
      case '-':
        sum += term;
        term = -number;
      case '*':
        term *= number;
      case '/':
        if (number == 0) return null;
        term /= number;
    }
    if (i + 1 < tokens.length) operation = tokens[i + 1];
  }
  final result = sum + term;
  if (!result.isFinite || result <= 0 || result > 999999999) return null;
  final rounded = result.round();
  return (result - rounded).abs() < 0.0000001 ? rounded : null;
}

String amountKey(String value, String key) {
  if (key == '⌫') {
    return value.isEmpty ? value : value.substring(0, value.length - 1);
  }
  if (key == '=') return moneyValue(value)?.toString() ?? value;
  return value.length < 80 ? value + key : value;
}
