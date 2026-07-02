class EcoPointsTransaction {
  final String id;
  final String guestId;
  final String sourceType;
  final String sourceRecordId;
  final String? sourceLabel;
  final int points;
  final double? carbonOffsetKg;
  final String status;
  final DateTime? earnedAt;

  EcoPointsTransaction({
    required this.id,
    required this.guestId,
    this.sourceType = 'MANUAL',
    this.sourceRecordId = '',
    this.sourceLabel,
    required this.points,
    this.carbonOffsetKg,
    this.status = 'COMPLETED',
    this.earnedAt,
  });

  factory EcoPointsTransaction.fromJson(Map<String, dynamic> json) {
    return EcoPointsTransaction(
      id: json['id'] ?? '',
      guestId: json['guest_id'] ?? '',
      sourceType: json['source_type'] ?? 'MANUAL',
      sourceRecordId: json['source_record_id'] ?? '',
      sourceLabel: json['source_label'],
      points: json['points'] ?? 0,
      carbonOffsetKg: (json['carbon_offset_kg'] as num?)?.toDouble(),
      status: json['status'] ?? 'COMPLETED',
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'source_type': sourceType,
      'source_record_id': sourceRecordId,
      'source_label': sourceLabel,
      'points': points,
      'carbon_offset_kg': carbonOffsetKg,
      'status': status,
    };
  }
}