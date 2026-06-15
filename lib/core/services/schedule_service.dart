import 'package:supabase_flutter/supabase_flutter.dart';

class GuestScheduleItem {
  final String id;
  final String guestId;
  final String title;
  final String itemType;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final String? description;
  final String status;
  final String color;
  final String? sourceModule;
  final String? notes;

  GuestScheduleItem({
    required this.id,
    required this.guestId,
    required this.title,
    required this.itemType,
    required this.startAt,
    required this.endAt,
    this.location,
    this.description,
    required this.status,
    required this.color,
    this.sourceModule,
    this.notes,
  });

  factory GuestScheduleItem.fromJson(Map<String, dynamic> json) {
    return GuestScheduleItem(
      id: json['id'] ?? '',
      guestId: json['guest_id'] ?? '',
      title: json['title'] ?? '',
      itemType: json['item_type'] ?? 'ACTIVITY',
      startAt: DateTime.parse(json['start_at'] ?? DateTime.now().toIso8601String()),
      endAt: DateTime.parse(json['end_at'] ?? DateTime.now().toIso8601String()),
      location: json['location'],
      description: json['description'],
      status: json['status'] ?? 'SCHEDULED',
      color: json['color'] ?? '#3B82F6',
      sourceModule: json['source_module'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'title': title,
      'item_type': itemType,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'location': location,
      'description': description,
      'status': status,
      'color': color,
      'source_module': sourceModule,
      'notes': notes,
    };
  }
}

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<GuestScheduleItem>> getScheduleForGuest(
    String guestId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client.from('guest_schedule_items').select('*').eq('guest_id', guestId);

      if (fromDate != null) {
        query = query.filter('start_at', 'gte', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.filter('start_at', 'lte', toDate.toIso8601String());
      }

      final response = await query.order('start_at', ascending: true);
      return response.map((e) => GuestScheduleItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<GuestScheduleItem>> getTodaysSchedule(String guestId) async {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    return getScheduleForGuest(guestId, fromDate: today, toDate: tomorrow);
  }
}