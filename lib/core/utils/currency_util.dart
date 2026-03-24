import '../config/app_config.dart';

class CurrencyUtil {
  CurrencyUtil._();

  /// Formats a number as Indian currency with ₹ symbol.
  ///
  /// Uses Indian number formatting: 1,00,000 (lakhs/crores grouping).
  /// Examples:
  ///   formatPrice(1500)      -> "₹1,500"
  ///   formatPrice(150000)    -> "₹1,50,000"
  ///   formatPrice(99.5)      -> "₹99.50"
  ///   formatPrice(1234567)   -> "₹12,34,567"
  static String formatPrice(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    // Split into integer and decimal parts
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Format integer part with Indian grouping
    final formattedInteger = _formatIndianNumber(integerPart);

    // Remove trailing zeros from decimal
    final trimmedDecimal = decimalPart == '00' ? '' : '.$decimalPart';

    final sign = isNegative ? '-' : '';
    return '$sign${AppConfig.currencySymbol}$formattedInteger$trimmedDecimal';
  }

  /// Formats price always showing 2 decimal places.
  ///
  /// Example: formatPriceFixed(99.5) -> "₹99.50"
  static String formatPriceFixed(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final formattedInteger = _formatIndianNumber(integerPart);

    final sign = isNegative ? '-' : '';
    return '$sign${AppConfig.currencySymbol}$formattedInteger.$decimalPart';
  }

  /// Formats an integer string with Indian number grouping.
  ///
  /// Indian grouping: first group of 3 from right, then groups of 2.
  /// Examples:
  ///   "1500"    -> "1,500"
  ///   "150000"  -> "1,50,000"
  ///   "1234567" -> "12,34,567"
  static String _formatIndianNumber(String number) {
    if (number.length <= 3) return number;

    // Last 3 digits
    final lastThree = number.substring(number.length - 3);
    final remaining = number.substring(0, number.length - 3);

    // Group remaining digits in pairs from right
    final buffer = StringBuffer();
    for (var i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }

    return '$buffer,$lastThree';
  }

  /// Formats a compact price (e.g., ₹1.5K, ₹2.3L).
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '${AppConfig.currencySymbol}${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${AppConfig.currencySymbol}${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${AppConfig.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatPrice(amount);
  }
}
