class SiteContentPage {
  final String id;
  final String slug;
  final String title;
  final String? subtitle;
  final String? body;
  final List<dynamic> highlights;
  final List<dynamic> metrics;
  final String? imagePath;
  final bool isActive;
  final dynamic metadata;

  SiteContentPage({
    required this.id,
    required this.slug,
    required this.title,
    this.subtitle,
    this.body,
    required this.highlights,
    required this.metrics,
    this.imagePath,
    required this.isActive,
    this.metadata,
  });

  factory SiteContentPage.fromJson(Map<String, dynamic> json) {
    return SiteContentPage(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      body: json['body'],
      highlights: (json['highlights'] as List<dynamic>?) ?? [],
      metrics: (json['metrics'] as List<dynamic>?) ?? [],
      imagePath: json['image_path'],
      isActive: json['is_active'] ?? true,
      metadata: json['metadata'],
    );
  }
}
