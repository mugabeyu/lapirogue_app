class Message {
  final String id;
  final String guestId;
  final String senderType;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  Message({
    required this.id,
    required this.guestId,
    required this.senderType,
    required this.content,
    required this.isRead,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      guestId: json['guest_id'] ?? '',
      senderType: json['sender_type'] ?? 'staff',
      content: json['content'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'sender_type': senderType,
      'content': content,
      'is_read': isRead,
    };
  }
}