import 'activity.dart';

class ActivityBooking {
  final String id;
  final String? activityId;
  final String? guestId;
  final DateTime bookingDate;
  final String? bookingTime;
  final int participants;
  final String status;
  final String? pickupPoint;
  final String? notes;
  final String? createdBy;
  final String? createdByName;
  final String? origin;
  final DateTime? createdAt;
  final Activity? activity;

  ActivityBooking({
    required this.id,
    this.activityId,
    this.guestId,
    required this.bookingDate,
    this.bookingTime,
    required this.participants,
    required this.status,
    this.pickupPoint,
    this.notes,
    this.createdBy,
    this.createdByName,
    this.origin,
    this.createdAt,
    this.activity,
  });

  factory ActivityBooking.fromJson(Map<String, dynamic> json) {
    return ActivityBooking(
      id: json['id'] ?? '',
      activityId: json['activity_id'],
      guestId: json['guest_id'],
      bookingDate: json['booking_date'] != null 
          ? DateTime.parse(json['booking_date']) 
          : DateTime.now(),
      bookingTime: json['booking_time'],
      participants: json['participants'] ?? 1,
      status: json['status'] ?? 'CONFIRMED',
      pickupPoint: json['pickup_point'],
      notes: json['notes'],
      createdBy: json['created_by'],
      createdByName: json['created_by_name'],
      origin: json['origin'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      activity: json['activities'] != null 
          ? Activity.fromJson(json['activities']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'guest_id': guestId,
      'booking_date': bookingDate.toIso8601String().split('T').first,
      'booking_time': bookingTime,
      'participants': participants,
      'status': status,
      'pickup_point': pickupPoint,
      'notes': notes,
      'created_by_name': createdByName,
      'origin': origin,
    };
  }
}
