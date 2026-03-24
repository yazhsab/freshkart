class PayoutModel {
  final String id;
  final String vendorId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final String status;
  final DateTime? paidAt;
  final String? referenceNumber;
  final DateTime createdAt;

  const PayoutModel({
    required this.id,
    required this.vendorId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.status,
    this.paidAt,
    this.referenceNumber,
    required this.createdAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      grossAmount: (json['gross_amount'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      referenceNumber: json['reference_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'gross_amount': grossAmount,
      'commission_amount': commissionAmount,
      'net_amount': netAmount,
      'status': status,
      'paid_at': paidAt?.toIso8601String(),
      'reference_number': referenceNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PayoutModel copyWith({
    String? id,
    String? vendorId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? grossAmount,
    double? commissionAmount,
    double? netAmount,
    String? status,
    DateTime? paidAt,
    String? referenceNumber,
    DateTime? createdAt,
  }) {
    return PayoutModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      grossAmount: grossAmount ?? this.grossAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      netAmount: netAmount ?? this.netAmount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
