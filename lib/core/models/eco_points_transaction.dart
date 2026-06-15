class EcoPointsTransaction {
  final String id;
  final String guestId;
  final String txType;
  final int points;
  final String? description;
  final String status;
  final DateTime? createdAt;

  EcoPointsTransaction({
    required this.id,
    required this.guestId,
    required this.txType,
    required this.points,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory EcoPointsTransaction.fromJson(Map<String, dynamic> json) {
    return EcoPointsTransaction(
      id: json['id'] ?? '',
      guestId: json['guest_id'] ?? '',
      txType: json['tx_type'] ?? 'EARN',
      points: json['points'] ?? 0,
      description: json['description'],
      status: json['status'] ?? 'COMPLETED',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'tx_type': txType,
      'points': points,
      'description': description,
      'status': status,
    };
  }
}