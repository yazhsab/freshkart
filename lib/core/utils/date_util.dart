import 'package:intl/intl.dart';

class DateUtil {
  DateUtil._();

  /// Formats a date as "15 Mar 2026".
  static String formatDate(DateTime date) {
    return DateFormat('d MMM y').format(date);
  }

  /// Formats time as "2:30 PM".
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Formats a delivery/service slot.
  ///
  /// Example: formatSlot(startTime, endTime) -> "9:00 AM - 11:00 AM"
  static String formatSlot(DateTime start, DateTime end) {
    final startStr = DateFormat('h:mm a').format(start);
    final endStr = DateFormat('h:mm a').format(end);
    return '$startStr - $endStr';
  }

  /// Formats an order date with time: "15 Mar 2026, 2:30 PM".
  static String formatOrderDate(DateTime date) {
    return DateFormat('d MMM y, h:mm a').format(date);
  }

  /// Returns a human-readable "time ago" string.
  ///
  /// Examples:
  ///   "Just now" (< 1 min)
  ///   "5 min ago"
  ///   "2 hours ago"
  ///   "Yesterday"
  ///   "3 days ago"
  ///   "15 Mar 2026" (> 7 days)
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return formatDate(dateTime);
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes min${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Formats date as "Today", "Tomorrow", "Yesterday", or "Mon, 15 Mar".
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return DateFormat('EEE, d MMM').format(date);
  }

  /// Formats day of week: "Monday", "Tuesday", etc.
  static String formatDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
}
