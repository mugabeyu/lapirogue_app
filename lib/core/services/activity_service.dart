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

      await _client.from('eco_points_tx').insert({
        'guest_id': guestId,
        'tx_type': 'EARN',
        'points': pointsToAward,
        'description': 'Completed activity: $activityName',
        'status': 'COMPLETED',
      });
      await _client.rpc('increment_eco_points', params: {
        'p_guest_id': guestId,
        'p_points': pointsToAward,
      });

      return true;
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
      await _client.rpc('increment_eco_points', params: {
        'p_guest_id': guestId,
        'p_points': points,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<EcoAction>> getEcoActions({bool activeOnly = true}) async {
    try {
      var query = _client.from('eco_actions').select('*');
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('points', ascending: false);
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
          .from('eco_actions')
          .select('title, points, description')
          .eq('id', actionId)
          .maybeSingle();

      if (actionResponse == null) return false;

      final actionTitle = actionResponse['title'] ?? 'Eco Action';
      final actionPoints = actionResponse['points'] ?? 0;

      await _client.from('eco_points_tx').insert({
        'guest_id': guestId,
        'tx_type': 'EARN',
        'points': actionPoints,
        'description': 'Participated in: $actionTitle',
        'status': 'COMPLETED',
      });

      await _client.from('guest_eco_actions').insert({
        'guest_id': guestId,
        'eco_action_id': actionId,
        'earned_points': actionPoints,
      });

      await _client.rpc('increment_eco_points', params: {
        'p_guest_id': guestId,
        'p_points': actionPoints,
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
