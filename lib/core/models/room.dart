class Room {
  final String id;
  final String roomNumber;
  final String type;
  final String? floor;
  final int capacity;
  final double price;
  final String status;
  final String? description;
  final List<String> amenities;
  final String? imagePath;
  final List<String> imagePaths;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Room({
    required this.id,
    required this.roomNumber,
    required this.type,
    this.floor,
    required this.capacity,
    required this.price,
    required this.status,
    this.description,
    required this.amenities,
    this.imagePath,
    required this.imagePaths,
    this.createdAt,
    this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      roomNumber: json['room_number'] ?? '',
      type: json['type'] ?? 'STANDARD',
      floor: json['floor'],
      capacity: json['capacity'] ?? 2,
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'AVAILABLE',
      description: json['description'],
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
      imagePath: json['image_path'],
      imagePaths: (json['image_paths'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_number': roomNumber,
      'type': type,
      'floor': floor,
      'capacity': capacity,
      'price': price,
      'status': status,
      'description': description,
      'amenities': amenities,
      'image_path': imagePath,
      'image_paths': imagePaths,
    };
  }
}