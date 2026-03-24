class DeliveryVendorModel {
  final String id;
  final String shopName;
  final String phone;
  final String address;
  final double lat;
  final double lng;

  const DeliveryVendorModel({
    required this.id,
    required this.shopName,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
  });

  factory DeliveryVendorModel.fromJson(Map<String, dynamic> json) {
    return DeliveryVendorModel(
      id: json['id'] as String,
      shopName: json['shop_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
