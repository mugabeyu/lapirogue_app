class Message {
  final String id;
  final String guestId;
  final String senderType;
  final String content;
  final bool isRead;
  final DateTime? createdAt;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;

  Message({
    required this.id,
    required this.guestId,
    required this.senderType,
    required this.content,
    required this.isRead,
    this.createdAt,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
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
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'sender_type': senderType,
      'content': content,
      'is_read': isRead,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
    };
  }
}