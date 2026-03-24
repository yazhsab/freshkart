class NotificationModel {
  final String id;
  final String userId;
  final String? refType;
  final String? refId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.refType,
    this.refId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      refType: json['ref_type'] as String?,
      refId: json['ref_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ref_type': refType,
      'ref_id': refId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? refType,
    String? refId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? sentAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
