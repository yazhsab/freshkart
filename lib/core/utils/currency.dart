import 'package:intl/intl.dart';

final _inrFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 2,
);

final _inrCompactFormat = NumberFormat.compactCurrency(
  locale: 'en_IN',
  symbol: '\u20B9',
  decimalDigits: 1,
);

String formatINR(double amount) {
  return _inrFormat.format(amount);
}

String formatINRCompact(double amount) {
  if (amount >= 100000) {
    return '\u20B9${(amount / 100000).toStringAsFixed(1)}L';
  }
  if (amount >= 1000) {
    return '\u20B9${(amount / 1000).toStringAsFixed(1)}K';
  }
  return _inrCompactFormat.format(amount);
}
