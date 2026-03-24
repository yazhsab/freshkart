class JobReportModel {
  final String bookingId;
  final String workerId;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String workDescription;
  final List<String> materialsUsed;
  final double additionalCharges;
  final String? additionalChargesNote;
  final String? signatureBase64;
  final String? signatureUrl;
  final int durationMinutes;

  const JobReportModel({
    required this.bookingId,
    required this.workerId,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.workDescription = '',
    this.materialsUsed = const [],
    this.additionalCharges = 0,
    this.additionalChargesNote,
    this.signatureBase64,
    this.signatureUrl,
    this.durationMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
    'booking_id': bookingId,
    'worker_id': workerId,
    'before_photos': beforePhotos,
    'after_photos': afterPhotos,
    'work_description': workDescription,
    'materials_used': materialsUsed,
    'additional_charges': additionalCharges,
    'additional_charges_note': additionalChargesNote,
    'signature_url': signatureUrl,
    'duration_minutes': durationMinutes,
  };

  factory JobReportModel.fromJson(Map<String, dynamic> json) {
    return JobReportModel(
      bookingId: json['booking_id'] as String,
      workerId: json['worker_id'] as String,
      beforePhotos:
          (json['before_photos'] as List<dynamic>?)?.cast<String>() ?? [],
      afterPhotos:
          (json['after_photos'] as List<dynamic>?)?.cast<String>() ?? [],
      workDescription: json['work_description'] as String? ?? '',
      materialsUsed:
          (json['materials_used'] as List<dynamic>?)?.cast<String>() ?? [],
      additionalCharges: (json['additional_charges'] as num?)?.toDouble() ?? 0,
      additionalChargesNote: json['additional_charges_note'] as String?,
      signatureUrl: json['signature_url'] as String?,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
    );
  }

  JobReportModel copyWith({
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? workDescription,
    List<String>? materialsUsed,
    double? additionalCharges,
    String? additionalChargesNote,
    String? signatureBase64,
    String? signatureUrl,
    int? durationMinutes,
  }) {
    return JobReportModel(
      bookingId: bookingId,
      workerId: workerId,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      workDescription: workDescription ?? this.workDescription,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      additionalChargesNote:
          additionalChargesNote ?? this.additionalChargesNote,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
