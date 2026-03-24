import 'package:intl/intl.dart';

class CurrencyUtil {
  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _formatterDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(double amount) => _formatter.format(amount);
  static String formatDecimal(double amount) =>
      _formatterDecimal.format(amount);
  static String compact(double amount) => _compact.format(amount);
}
