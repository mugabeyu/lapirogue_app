import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';
import '../models/eco_points_transaction.dart';
import '../models/eco_action.dart';

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
      if (kDebugMode) debugPrint('getAvailableActivities error: $e');
      return [];
    }
  }

  Future<bool> markActivityCompleted({
    required String bookingId,
    required String guestId,
  }) async {
    try {
      final booking = await _client
          .from('activity_bookings')
          .select('*, activities(name, price)')
          .eq('id', bookingId)
          .maybeSingle();

      if (booking == null) return false;

      final activityName = booking['activities']?['name'] ?? 'Activity';
      final activityPrice = (booking['activities']?['price'] ?? 0).toDouble();

      await _client
          .from('activity_bookings')
          .update({'status': 'COMPLETED'})
          .eq('id', bookingId);

      final ecoPoints = (activityPrice / 100).ceil() * 5;
      final pointsToAward = ecoPoints > 0 ? ecoPoints : 25;

      final result = await _client.rpc('log_eco_points', params: {
        'p_source_type': 'ACTIVITY',
        'p_source_record_id': bookingId,
        'p_source_label': 'Completed activity: $activityName',
        'p_points': pointsToAward,
      });

      return result != null && result['success'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('markActivityCompleted error: $e');
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
      final response = await _client.rpc(
        'get_guest_eco_points',
        params: {'p_guest_id': guestId},
      );
      return (response as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String> getEcoPointsTier(String guestId) async {
    try {
      final totalPoints = await getEcoPointsBalance(guestId);
      final tier = await _client
          .from('eco_tiers')
          .select('name')
          .lte('min_points', totalPoints)
          .order('min_points', ascending: false)
          .limit(1)
          .maybeSingle();
      return (tier?['name'] ?? 'Bronze') as String;
    } catch (e) {
      return 'Bronze';
    }
  }

  Future<List<EcoPointsTransaction>> getTransactions(String guestId) async {
    try {
      final response = await _client
          .from('guest_eco_point_events')
          .select('*')
          .eq('guest_id', guestId)
          .order('earned_at', ascending: false);
      return response.map((e) => EcoPointsTransaction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final response = await _client.rpc(
        'get_eco_leaderboard',
        params: {'p_limit': limit},
      );
      return (response as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> earnPoints({
    required String guestId,
    required int points,
    required String description,
    String sourceType = 'MANUAL',
    String? sourceRecordId,
  }) async {
    try {
      final result = await _client.rpc('log_eco_points', params: {
        'p_source_type': sourceType,
        'p_source_record_id': sourceRecordId ?? '',
        'p_source_label': description,
        'p_points': points,
      });
      return result != null && result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<List<EcoAction>> getEcoActions({bool activeOnly = true}) async {
    try {
      var query = _client.from('sustainability_activities').select('*');
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('default_points', ascending: false);
      return response.map((e) => EcoAction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> participateInEcoAction({
    required String guestId,
    required String actionId,
  }) async {
    try {
      final actionResponse = await _client
          .from('sustainability_activities')
          .select('name, default_points, carbon_offset_kg')
          .eq('id', actionId)
          .maybeSingle();

      if (actionResponse == null) return false;

      final actionName = actionResponse['name'] ?? 'Eco Action';
      final actionPoints = actionResponse['default_points'] ?? 0;
      final carbonOffset = actionResponse['carbon_offset_kg'] ?? 0;

      final result = await _client.rpc('log_eco_action', params: {
        'p_action_id': actionId,
        'p_source_type': 'ECO_ACTION',
        'p_source_record_id': actionId,
        'p_source_label': 'Participated in: $actionName',
        'p_points': actionPoints,
        'p_carbon_offset_kg': carbonOffset,
      });

      return result != null && result['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
