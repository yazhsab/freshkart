class ChatRoomModel {
  final String id;
  final String? orderId;
  final String? bookingId;
  final String customerId;
  final String otherPartyId;
  final String otherPartyType;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String? customerName;
  final String? customerAvatar;

  ChatRoomModel({
    required this.id,
    this.orderId,
    this.bookingId,
    required this.customerId,
    required this.otherPartyId,
    required this.otherPartyType,
    this.status = 'active',
    this.lastMessageAt,
    required this.createdAt,
    this.customerName,
    this.customerAvatar,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) => ChatRoomModel(
        id: json['id'],
        orderId: json['order_id'],
        bookingId: json['booking_id'],
        customerId: json['customer_id'],
        otherPartyId: json['other_party_id'],
        otherPartyType: json['other_party_type'],
        status: json['status'] ?? 'active',
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        customerName: json['profiles']?['full_name'],
        customerAvatar: json['profiles']?['avatar_url'],
      );
}

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String message;
  final String messageType;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.message,
    this.messageType = 'text',
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'],
        roomId: json['room_id'],
        senderId: json['sender_id'],
        message: json['message'],
        messageType: json['message_type'] ?? 'text',
        imageUrl: json['image_url'],
        isRead: json['is_read'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
        senderName: json['profiles']?['full_name'],
      );
}
