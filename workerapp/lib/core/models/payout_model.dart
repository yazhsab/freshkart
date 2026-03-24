class PayoutModel {
  final String id;
  final String workerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossAmount;
  final double commission;
  final double netAmount;
  final int jobCount;
  final String status;
  final DateTime? paidAt;

  const PayoutModel({
    required this.id,
    required this.workerId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossAmount,
    required this.commission,
    required this.netAmount,
    required this.jobCount,
    this.status = 'pending',
    this.paidAt,
  });

  bool get isPaid => status == 'paid';

  String get weekLabel {
    final startDay = '${periodStart.day}/${periodStart.month}';
    final endDay = '${periodEnd.day}/${periodEnd.month}';
    return '$startDay - $endDay';
  }

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      grossAmount: (json['gross_amount'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      jobCount: json['job_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
    );
  }
}
