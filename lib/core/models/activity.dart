class Activity {
  final String id;
  final String name;
  final String category;
  final String? description;
  final double price;
  final int duration;
  final int capacity;
  final String status;
  final String? imagePath;
  final String? meetingPoint;
  final String? defaultTime;

  Activity({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.price,
    required this.duration,
    required this.capacity,
    required this.status,
    this.imagePath,
    this.meetingPoint,
    this.defaultTime,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 60,
      capacity: json['capacity'] ?? 10,
      status: json['status'] ?? 'ACTIVE',
      imagePath: json['image_path'],
      meetingPoint: json['meeting_point'],
      defaultTime: json['default_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'duration': duration,
      'capacity': capacity,
      'status': status,
      'image_path': imagePath,
      'meeting_point': meetingPoint,
      'default_time': defaultTime,
    };
  }
}