import 'room.dart';

class Reservation {
  final String id;
  final String reservationId;
  final String? guestId;
  final String? roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final String status;
  final double totalAmount;
  final String? notes;
  final Room? room;

  Reservation({
    required this.id,
    required this.reservationId,
    this.guestId,
    this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.room,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? '',
      reservationId: json['reservation_id'] ?? '',
      guestId: json['guest_id'],
      roomId: json['room_id'],
      checkIn: json['check_in'] != null 
          ? DateTime.parse(json['check_in']) 
          : DateTime.now(),
      checkOut: json['check_out'] != null 
          ? DateTime.parse(json['check_out']) 
          : DateTime.now().add(const Duration(days: 1)),
      adults: json['adults'] ?? 1,
      children: json['children'] ?? 0,
      status: json['status'] ?? 'CONFIRMED',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      notes: json['notes'],
      room: json['rooms'] != null ? Room.fromJson(json['rooms']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'guest_id': guestId,
      'room_id': roomId,
      'check_in': checkIn.toIso8601String().split('T').first,
      'check_out': checkOut.toIso8601String().split('T').first,
      'adults': adults,
      'children': children,
      'status': status,
      'total_amount': totalAmount,
      'notes': notes,
    };
  }
}