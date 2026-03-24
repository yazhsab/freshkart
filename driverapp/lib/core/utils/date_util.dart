import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateUtil {
  DateUtil._();

  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _dayFormat = DateFormat('EEE, dd MMM');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime.toLocal());
  }

  static String formatDay(DateTime dateTime) {
    return _dayFormat.format(dateTime.toLocal());
  }

  static String formatMonthYear(DateTime dateTime) {
    return _monthYearFormat.format(dateTime.toLocal());
  }

  static String timeAgo(DateTime dateTime) {
    return timeago.format(dateTime, allowFromNow: false);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    }
    return '0m';
  }

  static String formatDurationFromMinutes(int totalMinutes) {
    return formatDuration(Duration(minutes: totalMinutes));
  }

  static String formatEta(int minutes) {
    if (minutes < 1) return 'Arriving';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }

  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final local = dateTime.toLocal();
    return local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
  }

  static String relativeDate(DateTime dateTime) {
    if (isToday(dateTime)) return 'Today';
    if (isYesterday(dateTime)) return 'Yesterday';
    return formatDate(dateTime);
  }
}
