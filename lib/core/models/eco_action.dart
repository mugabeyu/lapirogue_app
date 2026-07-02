class EcoAction {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final int defaultPoints;
  final double? carbonOffsetKg;
  final String? color;
  final bool isActive;

  EcoAction({
    required this.id,
    required this.name,
    this.category,
    this.description,
    required this.defaultPoints,
    this.carbonOffsetKg,
    this.color,
    required this.isActive,
  });

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
      defaultPoints: json['default_points'] ?? 0,
      carbonOffsetKg: (json['carbon_offset_kg'] as num?)?.toDouble(),
      color: json['color'],
      isActive: json['is_active'] ?? true,
    );
  }
}