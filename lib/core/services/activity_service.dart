import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';
import '../models/activity_booking.dart';
import '../models/eco_points_transaction.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<Activity>> getAvailableActivities() async {
    try {
      final response = await _client
          .from('activities')
          .select('*')
          .eq('status', 'ACTIVE')
          .order('name');
      return response.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ActivityBooking>> getMyBookings(String guestId) async {
    try {
      final response = await _client
          .from('activity_bookings')
          .select('*, activities(*)')
          .eq('guest_id', guestId)
          .order('booking_date', ascending: false);
      return response.map((e) => ActivityBooking.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> bookActivity({
    required String activityId,
    required String guestId,
    required DateTime bookingDate,
    String? bookingTime,
    int participants = 1,
    String? pickupPoint,
    String? notes,
  }) async {
    try {
      await _client.from('activity_bookings').insert({
        'activity_id': activityId,
        'guest_id': guestId,
        'booking_date': bookingDate.toIso8601String().split('T').first,
        'booking_time': bookingTime,
        'participants': participants,
        'pickup_point': pickupPoint,
        'notes': notes,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _client
          .from('activity_bookings')
          .update({'status': 'CANCELLED'})
          .eq('id', bookingId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class EcoPointsService {
  static final EcoPointsService _instance = EcoPointsService._internal();
  factory EcoPointsService() => _instance;
  EcoPointsService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<int> getEcoPointsBalance(String guestId) async {
    try {
      final response = await _client
          .from('eco_points_balance')
          .select('points')
          .eq('guest_id', guestId)
          .maybeSingle();
      return (response?['points'] ?? 0) as int;
    } catch (e) {
      return 0;
    }
  }

  Future<String> getEcoPointsTier(String guestId) async {
    try {
      final response = await _client
          .from('eco_points_balance')
          .select('tier')
          .eq('guest_id', guestId)
          .maybeSingle();
      return (response?['tier'] ?? 'Bronze') as String;
    } catch (e) {
      return 'Bronze';
    }
  }

  Future<List<EcoPointsTransaction>> getTransactions(String guestId) async {
    try {
      final response = await _client
          .from('eco_points_tx')
          .select('*')
          .eq('guest_id', guestId)
          .order('created_at', ascending: false);
      return response.map((e) => EcoPointsTransaction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _client
          .from('eco_points_balance')
          .select('*, guests(first_name, last_name)')
          .order('points', ascending: false)
          .limit(limit);
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<bool> earnPoints({
    required String guestId,
    required int points,
    required String description,
  }) async {
    try {
      await _client.from('eco_points_tx').insert({
        'guest_id': guestId,
        'tx_type': 'EARN',
        'points': points,
        'description': description,
        'status': 'COMPLETED',
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
