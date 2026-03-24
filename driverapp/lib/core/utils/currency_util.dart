import 'package:intl/intl.dart';
import '../config/app_config.dart';

class CurrencyUtil {
  CurrencyUtil._();

  static final NumberFormat _formatter = NumberFormat('#,##,###.##', 'en_IN');
  static final NumberFormat _wholeFormatter = NumberFormat('#,##,###', 'en_IN');

  static String format(double amount) {
    if (amount == amount.roundToDouble()) {
      return '${DeliveryAppConfig.currency}${_wholeFormatter.format(amount.round())}';
    }
    return '${DeliveryAppConfig.currency}${_formatter.format(amount)}';
  }

  static String formatCompact(double amount) {
    if (amount >= 100000) {
      return '${DeliveryAppConfig.currency}${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${DeliveryAppConfig.currency}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
