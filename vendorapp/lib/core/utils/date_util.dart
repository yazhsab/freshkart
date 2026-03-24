import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _dayOfWeekFormat = DateFormat('EEEE');

  /// Formats as "15 Mar 2026"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats as "02:30 PM"
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Formats as "15 Mar 2026, 02:30 PM"
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Returns relative time string like "2 minutes ago", "1 hour ago"
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (diff.inDays < 7) {
      final days = diff.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Returns "Today", "Yesterday", or formatted date
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '${_dayOfWeekFormat.format(date)}';
    return formatDate(date);
  }

  /// Returns full day name like "Monday"
  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  /// Checks if the date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Checks if the date falls within the current week (Monday to Sunday)
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endDate = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
      23,
      59,
      59,
    );
    return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endDate.add(const Duration(seconds: 1)));
  }
}
