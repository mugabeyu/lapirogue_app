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
  final String accountStatus;
  final String? notes;
  final String? imagePath;
  final String? homeAddress;
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
    this.accountStatus = 'ACTIVE',
    this.notes,
    this.imagePath,
    this.homeAddress,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.reservations,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] ?? '',
      authId: json['auth_id'] ?? json['auth_user_id'] ?? '',
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
      accountStatus: json['account_status'] ?? 'ACTIVE',
      notes: json['notes'],
      imagePath: json['image_path'],
      homeAddress: json['home_address'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
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
      'account_status': accountStatus,
      'notes': notes,
      'image_path': imagePath,
      'home_address': homeAddress,
      'created_by_name': createdByName,
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}