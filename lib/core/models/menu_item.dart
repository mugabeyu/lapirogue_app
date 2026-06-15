class MenuItem {
  final String id;
  final String name;
  final String category;
  final String? description;
  final double price;
  final int preparationMinutes;
  final bool isAvailable;
  final String? imagePath;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.price,
    required this.preparationMinutes,
    required this.isAvailable,
    this.imagePath,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      preparationMinutes: json['preparation_minutes'] ?? 15,
      isAvailable: json['is_available'] ?? true,
      imagePath: json['image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'preparation_minutes': preparationMinutes,
      'is_available': isAvailable,
      'image_path': imagePath,
    };
  }
}