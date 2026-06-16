class HotelServiceCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String colorHex;
  final int displayOrder;
  final bool isActive;

  HotelServiceCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.iconName = 'info',
    this.colorHex = '#14567D',
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory HotelServiceCategory.fromJson(Map<String, dynamic> json) {
    return HotelServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon_name'] ?? 'info',
      colorHex: json['color_hex'] ?? '#14567D',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}
