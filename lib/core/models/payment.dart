class Payment {
  final String id;
  final String paymentId;
  final String guestId;
  final String? reservationId;
  final double amount;
  final String method;
  final String status;
  final String? reference;
  final String? notes;
  final DateTime? createdAt;
  final List<dynamic> extraItems;

  Payment({
    required this.id,
    required this.paymentId,
    required this.guestId,
    this.reservationId,
    required this.amount,
    required this.method,
    required this.status,
    this.reference,
    this.notes,
    this.createdAt,
    required this.extraItems,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      paymentId: json['payment_id'] ?? '',
      guestId: json['guest_id'] ?? '',
      reservationId: json['reservation_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method'] ?? 'CASH',
      status: json['status'] ?? 'PENDING',
      reference: json['reference'],
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      extraItems: json['payment_extra_items'] ?? [],
    );
  }
}