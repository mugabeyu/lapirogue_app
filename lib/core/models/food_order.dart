class FoodOrder {
  final String id;
  final String orderId;
  final String? guestId;
  final String? roomId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double serviceCharge;
  final double taxAmount;
  final double total;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  FoodOrder({
    required this.id,
    required this.orderId,
    this.guestId,
    this.roomId,
    required this.items,
    required this.subtotal,
    required this.serviceCharge,
    required this.taxAmount,
    required this.total,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    return FoodOrder(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      guestId: json['guest_id'],
      roomId: json['room_id'],
      items: (json['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      serviceCharge: (json['service_charge'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'guest_id': guestId,
      'room_id': roomId,
      'items': items,
      'subtotal': subtotal,
      'service_charge': serviceCharge,
      'tax_amount': taxAmount,
      'total': total,
      'status': status,
      'notes': notes,
    };
  }
}