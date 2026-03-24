import 'profile.dart';

class Worker {
  final String id;
  final String profileId;
  final String? bio;
  final String? aadhaarNumber;
  final String? aadhaarDocUrl;
  final String? policeVerificationUrl;
  final List<String> skillCertificateUrls;
  final List<String> serviceCategoryIds;
  final int experienceYears;
  final String city;
  final List<String> servicePincodes;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final bool isAvailable;
  final bool isApproved;
  final String bgvStatus;
  final String? bgvNotes;
  final double rating;
  final int totalRatings;
  final int totalJobsCompleted;
  final DateTime? createdAt;
  final Profile? profile;

  Worker({
    required this.id,
    required this.profileId,
    this.bio,
    this.aadhaarNumber,
    this.aadhaarDocUrl,
    this.policeVerificationUrl,
    this.skillCertificateUrls = const [],
    this.serviceCategoryIds = const [],
    this.experienceYears = 0,
    this.city = 'Chennai',
    this.servicePincodes = const [],
    this.bankAccountNumber,
    this.bankIfsc,
    this.isAvailable = false,
    this.isApproved = false,
    this.bgvStatus = 'pending',
    this.bgvNotes,
    this.rating = 0,
    this.totalRatings = 0,
    this.totalJobsCompleted = 0,
    this.createdAt,
    this.profile,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      bio: json['bio'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      aadhaarDocUrl: json['aadhaar_doc_url'] as String?,
      policeVerificationUrl: json['police_verification_url'] as String?,
      skillCertificateUrls:
          (json['skill_certificate_urls'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      serviceCategoryIds:
          (json['service_category_ids'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      experienceYears: json['experience_years'] as int? ?? 0,
      city: json['city'] as String? ?? 'Chennai',
      servicePincodes:
          (json['service_pincodes'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      bgvStatus: json['bgv_status'] as String? ?? 'pending',
      bgvNotes: json['bgv_notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      totalJobsCompleted: json['total_jobs_completed'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'bio': bio,
        'aadhaar_number': aadhaarNumber,
        'aadhaar_doc_url': aadhaarDocUrl,
        'police_verification_url': policeVerificationUrl,
        'skill_certificate_urls': skillCertificateUrls,
        'service_category_ids': serviceCategoryIds,
        'experience_years': experienceYears,
        'city': city,
        'service_pincodes': servicePincodes,
        'bank_account_number': bankAccountNumber,
        'bank_ifsc': bankIfsc,
        'is_available': isAvailable,
        'is_approved': isApproved,
        'bgv_status': bgvStatus,
        'bgv_notes': bgvNotes,
      };

  String get displayName => profile?.displayName ?? 'Worker';
}
