class HotelService {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final String? phoneNumber;
  final String? email;
  final String? hoursText;
  final String? location;
  final String? imageUrl;
  final int sortOrder;
  final bool isAvailable;

  HotelService({required this.id, this.categoryId, required this.name, this.description, this.phoneNumber, this.email, this.hoursText, this.location, this.imageUrl, required this.sortOrder, required this.isAvailable});

  factory HotelService.fromJson(Map<String, dynamic> json) {
    return HotelService(
      id: json['id'] ?? '',
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      description: json['description'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      hoursText: json['hours_text'],
      location: json['location'],
      imageUrl: json['image_url'],
      sortOrder: json['sort_order'] ?? 0,
      isAvailable: json['is_available'] ?? true,
    );
  }
}
