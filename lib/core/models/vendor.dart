import 'profile.dart';

class Vendor {
  final String id;
  final String ownerId;
  final String shopName;
  final String? shopNameTamil;
  final String? description;
  final String? address;
  final String? pincode;
  final String city;
  final double? lat;
  final double? lng;
  final String? fssaiNumber;
  final String? fssaiDocUrl;
  final String? gstin;
  final String? gstinDocUrl;
  final double deliveryRadiusKm;
  final String? openingTime;
  final String? closingTime;
  final List<String> workingDays;
  final bool isOpen;
  final bool isApproved;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final DateTime? createdAt;
  final Profile? owner;
  final int orderCountToday;
  final double revenueThisWeek;

  Vendor({
    required this.id,
    required this.ownerId,
    required this.shopName,
    this.shopNameTamil,
    this.description,
    this.address,
    this.pincode,
    this.city = 'Chennai',
    this.lat,
    this.lng,
    this.fssaiNumber,
    this.fssaiDocUrl,
    this.gstin,
    this.gstinDocUrl,
    this.deliveryRadiusKm = 5,
    this.openingTime,
    this.closingTime,
    this.workingDays = const [],
    this.isOpen = false,
    this.isApproved = false,
    this.isActive = true,
    this.rating = 0,
    this.totalRatings = 0,
    this.createdAt,
    this.owner,
    this.orderCountToday = 0,
    this.revenueThisWeek = 0,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      shopName: json['shop_name'] as String? ?? '',
      shopNameTamil: json['shop_name_tamil'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      pincode: json['pincode'] as String?,
      city: json['city'] as String? ?? 'Chennai',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      fssaiNumber: json['fssai_number'] as String?,
      fssaiDocUrl: json['fssai_doc_url'] as String?,
      gstin: json['gstin'] as String?,
      gstinDocUrl: json['gstin_doc_url'] as String?,
      deliveryRadiusKm:
          (json['delivery_radius_km'] as num?)?.toDouble() ?? 5,
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      workingDays: (json['working_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isOpen: json['is_open'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      owner: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : (json['owner'] != null
              ? Profile.fromJson(json['owner'] as Map<String, dynamic>)
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'shop_name': shopName,
        'shop_name_tamil': shopNameTamil,
        'description': description,
        'address': address,
        'pincode': pincode,
        'city': city,
        'lat': lat,
        'lng': lng,
        'fssai_number': fssaiNumber,
        'fssai_doc_url': fssaiDocUrl,
        'gstin': gstin,
        'gstin_doc_url': gstinDocUrl,
        'delivery_radius_km': deliveryRadiusKm,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'working_days': workingDays,
        'is_open': isOpen,
        'is_approved': isApproved,
        'is_active': isActive,
      };

  String get status {
    if (!isActive) return 'suspended';
    if (!isApproved) return 'pending';
    return 'active';
  }
}
