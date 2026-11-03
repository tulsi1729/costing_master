const String inrSymbol = '₹';

const _gujaratiDigits = ['૦', '૧', '૨', '૩', '૪', '૫', '૬', '૭', '૮', '૯'];

/// Formats [value] with Indian digit grouping, e.g. `123456.5` → `1,23,456.50`.
String formatIndian(
  double value, {
  int decimals = 2,
  bool gujaratiDigits = false,
}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  final whole = dot == -1 ? fixed : fixed.substring(0, dot);
  final fraction = dot == -1 ? '' : fixed.substring(dot);

  final buffer = StringBuffer();
  if (whole.length <= 3) {
    buffer.write(whole);
  } else {
    final head = whole.substring(0, whole.length - 3);
    final tail = whole.substring(whole.length - 3);
    final firstGroup = head.length % 2;
    if (firstGroup == 1) buffer.write(head[0]);
    for (var i = firstGroup; i < head.length; i += 2) {
      if (buffer.isNotEmpty) buffer.write(',');
      buffer.write(head.substring(i, i + 2));
    }
    buffer
      ..write(',')
      ..write(tail);
  }

  final result = '${negative ? '-' : ''}$buffer$fraction';
  return gujaratiDigits ? toGujaratiDigits(result) : result;
}

/// `₹1,23,456.50`
String formatRupees(
  double value, {
  int decimals = 2,
  bool gujaratiDigits = false,
}) =>
    '$inrSymbol${formatIndian(value, decimals: decimals, gujaratiDigits: gujaratiDigits)}';

/// Formats a number the user typed, without trailing `.0` noise: `12.0` → `12`.
String formatInput(num? value) {
  if (value == null || value == 0) return '';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return double.parse(value.toStringAsFixed(4)).toString();
}

/// Formats a quantity for display: whole numbers without decimals.
String formatQty(num value, {bool gujaratiDigits = false}) {
  final text = value == value.roundToDouble()
      ? formatIndian(value.toDouble(), decimals: 0)
      : formatIndian(value.toDouble());
  return gujaratiDigits ? toGujaratiDigits(text) : text;
}

String toGujaratiDigits(String input) {
  final buffer = StringBuffer();
  for (final unit in input.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      buffer.write(_gujaratiDigits[unit - 0x30]);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Lenient numeric parse for user input (accepts `1,200`, blanks and Gujarati digits).
double parseAmount(String text) {
  final normalized = StringBuffer();
  for (final char in text.trim().split('')) {
    final gujaratiIndex = _gujaratiDigits.indexOf(char);
    if (gujaratiIndex != -1) {
      normalized.write(gujaratiIndex);
    } else if (char != ',') {
      normalized.write(char);
    }
  }
  return double.tryParse(normalized.toString()) ?? 0;
}
