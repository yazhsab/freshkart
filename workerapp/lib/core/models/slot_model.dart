import 'package:intl/intl.dart';

class SlotModel {
  final String id;
  final String workerId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isBooked;
  final String? bookingId;

  const SlotModel({
    required this.id,
    required this.workerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.bookingId,
  });

  String get timeLabel {
    try {
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      final fmt = DateFormat('h:mm a');
      return '${fmt.format(start)} - ${fmt.format(end)}';
    } catch (_) {
      return '$startTime - $endTime';
    }
  }

  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final slotDate = DateTime(date.year, date.month, date.day);
    if (slotDate.isBefore(today)) return true;
    if (slotDate.isAtSameMomentAs(today)) {
      final parts = endTime.split(':');
      final endHour = int.parse(parts[0]);
      final endMin = int.parse(parts[1]);
      return now.hour > endHour || (now.hour == endHour && now.minute > endMin);
    }
    return false;
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isBooked: json['is_booked'] as bool? ?? false,
      bookingId: json['booking_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'worker_id': workerId,
    'date': date.toIso8601String().split('T').first,
    'start_time': startTime,
    'end_time': endTime,
    'is_booked': isBooked,
    'booking_id': bookingId,
  };
}
