class DeliveryLocationModel {
  final String agentId;
  final String? orderId;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  const DeliveryLocationModel({
    required this.agentId,
    this.orderId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory DeliveryLocationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryLocationModel(
      agentId: json['agent_id'] as String,
      orderId: json['order_id'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'order_id': orderId,
      'lat': lat,
      'lng': lng,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
