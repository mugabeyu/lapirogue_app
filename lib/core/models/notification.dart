class AppNotification {
  final String id;
  final String? guestId;
  final String title;
  final String message;
  final String category;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    this.guestId,
    required this.title,
    required this.message,
    required this.category,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      guestId: json['guest_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: json['category'] ?? 'General',
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
      'title': title,
      'message': message,
      'category': category,
      'is_read': isRead,
    };
  }
}