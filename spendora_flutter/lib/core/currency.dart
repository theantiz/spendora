String formatInr(double amount, {bool withSign = false}) {
  final bool isNegative = amount < 0;
  final double absolute = amount.abs();
  final List<String> parts = absolute.toStringAsFixed(2).split('.');
  String intPart = parts.first;
  final String decimalPart = parts.last;

  if (intPart.length > 3) {
    final String lastThree = intPart.substring(intPart.length - 3);
    String remaining = intPart.substring(0, intPart.length - 3);
    final List<String> groups = <String>[];

    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      groups.insert(0, remaining);
    }

    intPart = '${groups.join(',')},$lastThree';
  }

  final String value = '₹$intPart.$decimalPart';
  if (withSign) {
    if (amount > 0) {
      return '+$value';
    }
    if (isNegative) {
      return '-$value';
    }
  }

  return isNegative ? '-$value' : value;
}
