import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

String timeAgoStr(DateTime dt) {
  return timeago.format(dt);
}

String formatDate(DateTime dt) {
  final ist = dt.toLocal();
  return DateFormat('dd MMM yyyy').format(ist);
}

String formatDateTime(DateTime dt) {
  final ist = dt.toLocal();
  return DateFormat('dd MMM yyyy, hh:mm a').format(ist);
}

String formatSlot(DateTime date, String start, String end) {
  final dayStr = DateFormat('EEE dd MMM').format(date);
  return '$dayStr, $start\u2013$end';
}

String formatTimeOnly(DateTime dt) {
  return DateFormat('hh:mm a').format(dt.toLocal());
}

DateTime todayStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime daysAgo(int days) {
  return todayStart().subtract(Duration(days: days));
}
