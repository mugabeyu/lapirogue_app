class GuestScheduleItem {
  final String id;
  final String guestId;
  final String title;
  final String itemType;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final String? description;
  final String status;
  final String color;
  final String? sourceModule;
  final String? notes;

  GuestScheduleItem({
    required this.id,
    required this.guestId,
    required this.title,
    required this.itemType,
    required this.startAt,
    required this.endAt,
    this.location,
    this.description,
    required this.status,
    required this.color,
    this.sourceModule,
    this.notes,
  });

  factory GuestScheduleItem.fromJson(Map<String, dynamic> json) {
    return GuestScheduleItem(
      id: json['id'] ?? '',
      guestId: json['guest_id'] ?? '',
      title: json['title'] ?? '',
      itemType: json['item_type'] ?? 'ACTIVITY',
      startAt: DateTime.parse(json['start_at'] ?? DateTime.now().toIso8601String()),
      endAt: DateTime.parse(json['end_at'] ?? DateTime.now().toIso8601String()),
      location: json['location'],
      description: json['description'],
      status: json['status'] ?? 'SCHEDULED',
      color: json['color'] ?? '#3B82F6',
      sourceModule: json['source_module'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'title': title,
      'item_type': itemType,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'location': location,
      'description': description,
      'status': status,
      'color': color,
      'source_module': sourceModule,
      'notes': notes,
    };
  }
}