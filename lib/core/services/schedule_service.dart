import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest_schedule_item.dart';

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