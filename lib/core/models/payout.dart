class Payout {
  final String id;
  final String? payeeType;
  final String payeeId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double? grossAmount;
  final double? commissionAmount;
  final double? netAmount;
  final String status;
  final String? paymentReference;
  final DateTime? paidAt;
  final String? notes;
  final DateTime? createdAt;

  Payout({
    required this.id,
    this.payeeType,
    required this.payeeId,
    this.periodStart,
    this.periodEnd,
    this.grossAmount,
    this.commissionAmount,
    this.netAmount,
    this.status = 'pending',
    this.paymentReference,
    this.paidAt,
    this.notes,
    this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      payeeType: json['payee_type'] as String?,
      payeeId: json['payee_id'] as String,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,
      grossAmount: (json['gross_amount'] as num?)?.toDouble(),
      commissionAmount:
          (json['commission_amount'] as num?)?.toDouble(),
      netAmount: (json['net_amount'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentReference: json['payment_reference'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'payee_type': payeeType,
        'payee_id': payeeId,
        'period_start': periodStart?.toIso8601String().split('T')[0],
        'period_end': periodEnd?.toIso8601String().split('T')[0],
        'gross_amount': grossAmount,
        'commission_amount': commissionAmount,
        'net_amount': netAmount,
        'status': status,
        'payment_reference': paymentReference,
        'notes': notes,
      };
}
