class EcoPointsBalance {
  final String guestId;
  final int points;
  final String tier;

  EcoPointsBalance({
    required this.guestId,
    required this.points,
    required this.tier,
  });

  factory EcoPointsBalance.fromJson(Map<String, dynamic> json) {
    return EcoPointsBalance(
      guestId: json['guest_id'] ?? '',
      points: json['points'] ?? 0,
      tier: json['tier'] ?? 'Bronze',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guest_id': guestId,
      'points': points,
      'tier': tier,
    };
  }
}