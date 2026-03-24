class AddressModel {
  final String id;
  final String userId;
  final String label;
  final String flatNo;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.flatNo,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String,
      flatNo: json['flat_no'] as String,
      area: json['area'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      isDefault: json['is_default'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'flat_no': flatNo,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? flatNo,
    String? area,
    String? city,
    String? state,
    String? pincode,
    double? lat,
    double? lng,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      flatNo: flatNo ?? this.flatNo,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
