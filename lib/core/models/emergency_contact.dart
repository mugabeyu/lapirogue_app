class EmergencyContact {
  final String id;
  final String name;
  final String description;
  final String phoneNumber;
  final String iconName;
  final String colorHex;
  final String? bgColorHex;
  final bool is24h;
  final int displayOrder;
  final bool isActive;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.description,
    required this.phoneNumber,
    this.iconName = 'warning',
    this.colorHex = '#EF4444',
    this.bgColorHex,
    this.is24h = true,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      iconName: json['icon_name'] ?? 'warning',
      colorHex: json['color_hex'] ?? '#EF4444',
      bgColorHex: json['bg_color_hex'],
      is24h: json['is_24h'] ?? true,
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}
