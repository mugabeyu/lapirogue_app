import 'reservation.dart';

class Guest {
  final String id;
  final String authId;
  final String guestId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? nationality;
  final String? passport;
  final DateTime? dateOfBirth;
  final bool vip;
  final String status;
  final String? notes;
  final String? imagePath;
  final List<Reservation>? reservations;

  Guest({
    required this.id,
    required this.authId,
    required this.guestId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.nationality,
    this.passport,
    this.dateOfBirth,
    required this.vip,
    required this.status,
    this.notes,
    this.imagePath,
    this.reservations,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] ?? '',
      authId: json['auth_id'] ?? '',
      guestId: json['guest_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      nationality: json['nationality'],
      passport: json['passport'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      vip: json['vip'] ?? false,
      status: json['status'] ?? 'RESERVED',
      notes: json['notes'],
      imagePath: json['image_path'],
      reservations: json['reservations'] != null
          ? (json['reservations'] as List)
              .map((e) => Reservation.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'guest_id': guestId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'nationality': nationality,
      'passport': passport,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'vip': vip,
      'status': status,
      'notes': notes,
      'image_path': imagePath,
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}