class EcoAction {
  final String id;
  final String title;
  final String description;
  final int points;
  final String iconName;
  final bool isActive;

  EcoAction({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.iconName,
    required this.isActive,
  });

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      iconName: json['icon_name'] ?? 'eco',
      isActive: json['is_active'] ?? true,
    );
  }
}