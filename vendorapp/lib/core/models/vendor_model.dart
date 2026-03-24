class VendorModel {
  final String id;
  final String ownerId;
  final String shopName;
  final String? shopNameTamil;
  final String? description;
  final String address;
  final String pincode;
  final String city;
  final double lat;
  final double lng;
  final String? openingTime;
  final String? closingTime;
  final bool isOpen;
  final bool isApproved;
  final bool isActive;
  final double rating;
  final int totalRatings;
  final double deliveryRadiusKm;
  final double minOrderAmount;
  final double commissionPct;
  final String? fssaiNumber;
  final String? gstinNumber;
  final String? shopPhone;
  final String? fssaiDocUrl;
  final String? gstinDocUrl;
  final List<String> workingDays;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankAccountHolderName;
  final DateTime createdAt;

  const VendorModel({
    required this.id,
    required this.ownerId,
    required this.shopName,
    this.shopNameTamil,
    this.description,
    required this.address,
    required this.pincode,
    required this.city,
    required this.lat,
    required this.lng,
    this.openingTime,
    this.closingTime,
    this.isOpen = false,
    this.isApproved = false,
    this.isActive = true,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.deliveryRadiusKm = 5.0,
    this.minOrderAmount = 0.0,
    this.commissionPct = 10.0,
    this.shopPhone,
    this.fssaiDocUrl,
    this.gstinDocUrl,
    this.workingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.fssaiNumber,
    this.gstinNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankAccountHolderName,
    required this.createdAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      shopName: json['shop_name'] as String,
      shopNameTamil: json['shop_name_tamil'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String,
      pincode: json['pincode'] as String,
      city: json['city'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      isOpen: json['is_open'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      deliveryRadiusKm: (json['delivery_radius_km'] as num?)?.toDouble() ?? 5.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      commissionPct: (json['commission_pct'] as num?)?.toDouble() ?? 10.0,
      shopPhone: json['shop_phone'] as String?,
      fssaiDocUrl: json['fssai_doc_url'] as String?,
      gstinDocUrl: json['gstin_doc_url'] as String?,
      workingDays:
          (json['working_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      fssaiNumber: json['fssai_number'] as String?,
      gstinNumber: json['gstin_number'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      bankAccountHolderName: json['bank_account_holder_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'opening_time': openingTime,
      'closing_time': closingTime,
      'is_open': isOpen,
      'is_approved': isApproved,
      'is_active': isActive,
      'rating': rating,
      'total_ratings': totalRatings,
      'delivery_radius_km': deliveryRadiusKm,
      'min_order_amount': minOrderAmount,
      'commission_pct': commissionPct,
      'shop_phone': shopPhone,
      'fssai_doc_url': fssaiDocUrl,
      'gstin_doc_url': gstinDocUrl,
      'working_days': workingDays,
      'fssai_number': fssaiNumber,
      'gstin_number': gstinNumber,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'bank_account_holder_name': bankAccountHolderName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VendorModel copyWith({
    String? id,
    String? ownerId,
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
    double? minOrderAmount,
    double? commissionPct,
    String? shopPhone,
    String? fssaiDocUrl,
    String? gstinDocUrl,
    List<String>? workingDays,
    String? fssaiNumber,
    String? gstinNumber,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankAccountHolderName,
    DateTime? createdAt,
  }) {
    return VendorModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
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
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      commissionPct: commissionPct ?? this.commissionPct,
      shopPhone: shopPhone ?? this.shopPhone,
      fssaiDocUrl: fssaiDocUrl ?? this.fssaiDocUrl,
      gstinDocUrl: gstinDocUrl ?? this.gstinDocUrl,
      workingDays: workingDays ?? this.workingDays,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
      gstinNumber: gstinNumber ?? this.gstinNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankAccountHolderName:
          bankAccountHolderName ?? this.bankAccountHolderName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
