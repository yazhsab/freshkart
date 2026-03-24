import 'package:intl/intl.dart';

class DateUtil {
  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);
  static String formatDateShort(DateTime date) =>
      DateFormat('dd MMM').format(date);
  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);
  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM, h:mm a').format(date);
  static String formatDay(DateTime date) =>
      DateFormat('EEE, dd MMM').format(date);
  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(date);
    return formatDate(date);
  }

  static String timerFormat(Duration duration) {
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  static String durationFormat(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
