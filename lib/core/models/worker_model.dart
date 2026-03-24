import 'user_model.dart';

class WorkerModel {
  final String id;
  final String profileId;
  final String? bio;
  final List<String> serviceCategoryIds;
  final int experienceYears;
  final String city;
  final List<String> servicePincodes;
  final bool isAvailable;
  final bool isApproved;
  final double rating;
  final int totalRatings;
  final int totalJobsCompleted;
  final UserModel? profile;

  const WorkerModel({
    required this.id,
    required this.profileId,
    this.bio,
    required this.serviceCategoryIds,
    required this.experienceYears,
    required this.city,
    required this.servicePincodes,
    required this.isAvailable,
    required this.isApproved,
    required this.rating,
    required this.totalRatings,
    required this.totalJobsCompleted,
    this.profile,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      bio: json['bio'] as String?,
      serviceCategoryIds:
          (json['service_category_ids'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      experienceYears: json['experience_years'] as int,
      city: json['city'] as String,
      servicePincodes:
          (json['service_pincodes'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      isAvailable: json['is_available'] as bool,
      isApproved: json['is_approved'] as bool,
      rating: (json['rating'] as num).toDouble(),
      totalRatings: json['total_ratings'] as int,
      totalJobsCompleted: json['total_jobs_completed'] as int,
      profile: json['profile'] != null
          ? UserModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'bio': bio,
      'service_category_ids': serviceCategoryIds,
      'experience_years': experienceYears,
      'city': city,
      'service_pincodes': servicePincodes,
      'is_available': isAvailable,
      'is_approved': isApproved,
      'rating': rating,
      'total_ratings': totalRatings,
      'total_jobs_completed': totalJobsCompleted,
      'profile': profile?.toJson(),
    };
  }

  WorkerModel copyWith({
    String? id,
    String? profileId,
    String? bio,
    List<String>? serviceCategoryIds,
    int? experienceYears,
    String? city,
    List<String>? servicePincodes,
    bool? isAvailable,
    bool? isApproved,
    double? rating,
    int? totalRatings,
    int? totalJobsCompleted,
    UserModel? profile,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      bio: bio ?? this.bio,
      serviceCategoryIds: serviceCategoryIds ?? this.serviceCategoryIds,
      experienceYears: experienceYears ?? this.experienceYears,
      city: city ?? this.city,
      servicePincodes: servicePincodes ?? this.servicePincodes,
      isAvailable: isAvailable ?? this.isAvailable,
      isApproved: isApproved ?? this.isApproved,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      profile: profile ?? this.profile,
    );
  }
}
