class CouponModel {
  final String id;
  final String code;
  final String title;
  final String? titleTamil;
  final String? description;
  final String? descriptionTamil;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderAmount;
  final int? usageLimit;
  final int perUserLimit;
  final int usedCount;
  final String? vendorId;
  final String? categoryId;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    this.titleTamil,
    this.description,
    this.descriptionTamil,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minOrderAmount = 0,
    this.usageLimit,
    this.perUserLimit = 1,
    this.usedCount = 0,
    this.vendorId,
    this.categoryId,
    this.validFrom,
    this.validUntil,
    this.isActive = true,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
    id: json['id'],
    code: json['code'],
    title: json['title'],
    titleTamil: json['title_tamil'],
    description: json['description'],
    descriptionTamil: json['description_tamil'],
    discountType: json['discount_type'],
    discountValue: (json['discount_value'] as num).toDouble(),
    maxDiscount: json['max_discount'] != null ? (json['max_discount'] as num).toDouble() : null,
    minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
    usageLimit: json['usage_limit'],
    perUserLimit: json['per_user_limit'] ?? 1,
    usedCount: json['used_count'] ?? 0,
    vendorId: json['vendor_id'],
    categoryId: json['category_id'],
    validFrom: json['valid_from'] != null ? DateTime.parse(json['valid_from']) : null,
    validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'title_tamil': titleTamil,
    'description': description,
    'description_tamil': descriptionTamil,
    'discount_type': discountType,
    'discount_value': discountValue,
    'max_discount': maxDiscount,
    'min_order_amount': minOrderAmount,
    'usage_limit': usageLimit,
    'per_user_limit': perUserLimit,
    'vendor_id': vendorId,
    'category_id': categoryId,
    'valid_from': validFrom?.toIso8601String(),
    'valid_until': validUntil?.toIso8601String(),
  };

  String get discountLabel => discountType == 'percentage'
      ? '${discountValue.toInt()}% OFF'
      : '₹${discountValue.toInt()} OFF';
}
