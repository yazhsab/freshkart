class VendorModel {
  final String id;
  final String shopName;
  final String? shopNameTamil;
  final String? description;
  final String address;
  final String pincode;
  final String city;
  final double lat;
  final double lng;
  final String openingTime;
  final String closingTime;
  final bool isOpen;
  final bool isApproved;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final double deliveryRadiusKm;
  final double? distance;
  final int? estimatedDeliveryMins;

  const VendorModel({
    required this.id,
    required this.shopName,
    this.shopNameTamil,
    this.description,
    required this.address,
    required this.pincode,
    required this.city,
    required this.lat,
    required this.lng,
    required this.openingTime,
    required this.closingTime,
    required this.isOpen,
    required this.isApproved,
    required this.isActive,
    required this.rating,
    required this.totalRatings,
    required this.deliveryRadiusKm,
    this.distance,
    this.estimatedDeliveryMins,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      shopName: json['shop_name'] as String,
      shopNameTamil: json['shop_name_tamil'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String,
      pincode: json['pincode'] as String,
      city: json['city'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      openingTime: json['opening_time'] as String,
      closingTime: json['closing_time'] as String,
      isOpen: json['is_open'] as bool,
      isApproved: json['is_approved'] as bool,
      isActive: json['is_active'] as bool,
      rating: (json['rating'] as num).toDouble(),
      totalRatings: json['total_ratings'] as int,
      deliveryRadiusKm: (json['delivery_radius_km'] as num).toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      estimatedDeliveryMins: json['estimated_delivery_mins'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_name': shopName,
      'shop_name_tamil': shopNameTamil,
      'description': description,
      'address': address,
      'pincode': pincode,
      'city': city,
      'lat': lat,
      'lng': lng,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'is_open': isOpen,
      'is_approved': isApproved,
      'is_active': isActive,
      'rating': rating,
      'total_ratings': totalRatings,
      'delivery_radius_km': deliveryRadiusKm,
      'distance': distance,
      'estimated_delivery_mins': estimatedDeliveryMins,
    };
  }

  VendorModel copyWith({
    String? id,
    String? shopName,
    String? shopNameTamil,
    String? description,
    String? address,
    String? pincode,
    String? city,
    double? lat,
    double? lng,
    String? openingTime,
    String? closingTime,
    bool? isOpen,
    bool? isApproved,
    bool? isActive,
    double? rating,
    int? totalRatings,
    double? deliveryRadiusKm,
    double? distance,
    int? estimatedDeliveryMins,
  }) {
    return VendorModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      shopNameTamil: shopNameTamil ?? this.shopNameTamil,
      description: description ?? this.description,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      isOpen: isOpen ?? this.isOpen,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      distance: distance ?? this.distance,
      estimatedDeliveryMins: estimatedDeliveryMins ?? this.estimatedDeliveryMins,
    );
  }
}
