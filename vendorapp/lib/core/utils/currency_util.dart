import 'package:intl/intl.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';

class CurrencyUtil {
  CurrencyUtil._();

  static final _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: VendorAppConfig.currency,
    decimalDigits: 2,
  );

  static final _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: VendorAppConfig.currency,
    decimalDigits: 1,
  );

  /// Formats price in Indian number format: ₹X,XX,XXX.XX
  static String formatPrice(double amount) {
    return _indianFormat.format(amount);
  }

  /// Formats price in compact form: ₹1.2K, ₹15.3L
  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }
}
