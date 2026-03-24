class ZoneModel {
  final String id;
  final String name;
  final String? nameTamil;
  final String? district;
  final String? city;
  final String state;
  final List<String> pincodes;
  final double? deliveryFeeOverride;
  final double? minOrderAmount;
  final double? maxCodAmount;
  final bool isActive;

  ZoneModel({
    required this.id,
    required this.name,
    this.nameTamil,
    this.district,
    this.city,
    this.state = 'Tamil Nadu',
    this.pincodes = const [],
    this.deliveryFeeOverride,
    this.minOrderAmount,
    this.maxCodAmount,
    this.isActive = true,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) => ZoneModel(
    id: json['id'],
    name: json['name'],
    nameTamil: json['name_tamil'],
    district: json['district'],
    city: json['city'],
    state: json['state'] ?? 'Tamil Nadu',
    pincodes: (json['pincodes'] as List?)?.map((e) => e.toString()).toList() ?? [],
    deliveryFeeOverride: (json['delivery_fee_override'] as num?)?.toDouble(),
    minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
    maxCodAmount: (json['max_cod_amount'] as num?)?.toDouble(),
    isActive: json['is_active'] ?? true,
  );
}
