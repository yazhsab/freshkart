class PayoutModel {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int deliveryCount;
  final double totalAmount;
  final String status; // pending, processing, paid
  final DateTime? paidAt;
  final String? referenceNumber;

  const PayoutModel({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    this.deliveryCount = 0,
    required this.totalAmount,
    required this.status,
    this.paidAt,
    this.referenceNumber,
  });

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isPaid => status == 'paid';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'paid':
        return 'Paid';
      default:
        return status;
    }
  }

  String get weekRange {
    final startDay = '${weekStart.day}/${weekStart.month}';
    final endDay = '${weekEnd.day}/${weekEnd.month}';
    return '$startDay - $endDay';
  }

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      deliveryCount: (json['delivery_count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      referenceNumber: json['reference_number'] as String?,
    );
  }
}
