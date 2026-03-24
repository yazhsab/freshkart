class WorkerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String city;
  final List<String> pincodes;
  final List<String> skills;
  final int experienceYears;
  final String? bio;
  final String? profilePhotoUrl;
  final String? aadhaarNumber;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankName;
  final String bgvStatus;
  final double rating;
  final int totalJobs;
  final int completedJobs;
  final bool isAvailable;
  final bool isActive;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.city,
    this.pincodes = const [],
    this.skills = const [],
    this.experienceYears = 0,
    this.bio,
    this.profilePhotoUrl,
    this.aadhaarNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankName,
    this.bgvStatus = 'pending',
    this.rating = 0,
    this.totalJobs = 0,
    this.completedJobs = 0,
    this.isAvailable = false,
    this.isActive = true,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  String get maskedAadhaar {
    if (aadhaarNumber == null || aadhaarNumber!.length < 4) return '****';
    return 'XXXX-XXXX-${aadhaarNumber!.substring(aadhaarNumber!.length - 4)}';
  }

  String get maskedBankAccount {
    if (bankAccountNumber == null || bankAccountNumber!.length < 4)
      return '****';
    return 'XXXX${bankAccountNumber!.substring(bankAccountNumber!.length - 4)}';
  }

  String get skillsLabel => skills.join(', ');

  bool get isBgvApproved => bgvStatus == 'approved';
  bool get isBgvPending => bgvStatus == 'pending';
  bool get isBgvRejected => bgvStatus == 'rejected';

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      city: json['city'] as String? ?? '',
      pincodes: (json['pincodes'] as List<dynamic>?)?.cast<String>() ?? [],
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      experienceYears: json['experience_years'] as int? ?? 0,
      bio: json['bio'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      bankName: json['bank_name'] as String?,
      bgvStatus: json['bgv_status'] as String? ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalJobs: json['total_jobs'] as int? ?? 0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
    'pincodes': pincodes,
    'skills': skills,
    'experience_years': experienceYears,
    'bio': bio,
    'profile_photo_url': profilePhotoUrl,
    'aadhaar_number': aadhaarNumber,
    'bank_account_number': bankAccountNumber,
    'bank_ifsc': bankIfsc,
    'bank_name': bankName,
    'bgv_status': bgvStatus,
    'rating': rating,
    'total_jobs': totalJobs,
    'completed_jobs': completedJobs,
    'is_available': isAvailable,
    'is_active': isActive,
    'fcm_token': fcmToken,
  };

  WorkerModel copyWith({
    String? name,
    String? email,
    String? city,
    List<String>? pincodes,
    List<String>? skills,
    int? experienceYears,
    String? bio,
    String? profilePhotoUrl,
    String? bgvStatus,
    double? rating,
    int? totalJobs,
    int? completedJobs,
    bool? isAvailable,
    bool? isActive,
    String? fcmToken,
  }) {
    return WorkerModel(
      id: id,
      name: name ?? this.name,
      phone: phone,
      email: email ?? this.email,
      city: city ?? this.city,
      pincodes: pincodes ?? this.pincodes,
      skills: skills ?? this.skills,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      aadhaarNumber: aadhaarNumber,
      bankAccountNumber: bankAccountNumber,
      bankIfsc: bankIfsc,
      bankName: bankName,
      bgvStatus: bgvStatus ?? this.bgvStatus,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      completedJobs: completedJobs ?? this.completedJobs,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
