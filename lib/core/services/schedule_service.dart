import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guest_schedule_item.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<bool> createCustomItem({
    required String guestId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    String? notes,
  }) async {
    try {
      final end = endAt ?? startAt.add(const Duration(hours: 1));
      await _client.from('guest_schedule_items').insert({
        'guest_id': guestId,
        'title': title,
        'item_type': 'CUSTOM',
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': end.toUtc().toIso8601String(),
        'description': notes?.trim() ?? '',
        'status': 'SCHEDULED',
        'color': '#E7D7F0',
        'source_module': 'guest_app',
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('createCustomItem error: $e');
      return false;
    }
  }

  Future<List<GuestScheduleItem>> getScheduleForGuest(
    String guestId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final results = await Future.wait([
        _client.from('guest_schedule_items').select('*').eq('guest_id', guestId).order('start_at'),
        _client.from('activity_bookings').select('*, activities(name)').eq('guest_id', guestId).order('booking_date'),
        _client.from('food_orders').select('*').eq('guest_id', guestId).order('created_at'),
        _client.from('reservations').select('*, rooms(*)').eq('guest_id', guestId).order('check_in'),
      ]);

      final items = <GuestScheduleItem>[];

      for (final json in results[0]) {
        items.add(GuestScheduleItem.fromJson(json));
      }

      for (final json in results[1]) {
        final bookingDate = DateTime.parse(json['booking_date'] ?? DateTime.now().toIso8601String());
        final timeParts = (json['booking_time'] ?? '09:00').split(':');
        final startAt = DateTime(
          bookingDate.year, bookingDate.month, bookingDate.day,
          int.tryParse(timeParts[0]) ?? 9, int.tryParse(timeParts[1]) ?? 0,
        );
        items.add(GuestScheduleItem(
          id: json['id'] ?? '',
          guestId: json['guest_id'] ?? '',
          title: json['activities']?['name'] ?? 'Activity',
          itemType: 'ACTIVITY',
          startAt: startAt,
          endAt: startAt.add(const Duration(hours: 1)),
          location: json['pickup_point'],
          description: json['notes'],
          status: json['status'] ?? 'SCHEDULED',
          color: '#F4A340',
          sourceModule: 'activity_bookings',
          notes: json['notes'],
        ));
      }

      for (final json in results[2]) {
        final scheduledDate = json['scheduled_date'] as String?;
        final scheduledTime = json['scheduled_time'] as String?;
        DateTime startAt;
        if (scheduledDate != null && scheduledTime != null) {
          final timeParts = scheduledTime.split(':');
          final date = DateTime.parse(scheduledDate);
          startAt = DateTime(
            date.year, date.month, date.day,
            int.tryParse(timeParts[0]) ?? 9, int.tryParse(timeParts[1]) ?? 0,
          );
        } else {
          startAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now();
        }
        items.add(GuestScheduleItem(
          id: json['id'] ?? '',
          guestId: json['guest_id'] ?? '',
          title: 'Food Order #${json['order_id'] ?? json['id']?.toString().substring(0, 8)}',
          itemType: 'ORDER',
          startAt: startAt,
          endAt: startAt.add(const Duration(minutes: 30)),
          description: json['notes'],
          status: json['status'] ?? 'PENDING',
          color: '#4CAF50',
          sourceModule: 'food_orders',
          notes: json['notes'],
        ));
      }

      for (final json in results[3]) {
        final room = json['rooms'];
        final roomLabel = room != null ? 'Room ${room['room_number'] ?? '--'}' : '';
        final checkIn = DateTime.parse(json['check_in'] ?? DateTime.now().toIso8601String());
        final checkOut = DateTime.parse(json['check_out'] ?? DateTime.now().toIso8601String());

        items.add(GuestScheduleItem(
          id: 'checkin_${json['id']}',
          guestId: json['guest_id'] ?? '',
          title: 'Check-In${roomLabel.isNotEmpty ? ' - $roomLabel' : ''}',
          itemType: 'RESERVATION',
          startAt: checkIn,
          endAt: checkIn.add(const Duration(hours: 2)),
          status: json['status'] ?? 'CONFIRMED',
          color: '#002B5C',
          sourceModule: 'reservations',
        ));

        items.add(GuestScheduleItem(
          id: 'checkout_${json['id']}',
          guestId: json['guest_id'] ?? '',
          title: 'Check-Out${roomLabel.isNotEmpty ? ' - $roomLabel' : ''}',
          itemType: 'RESERVATION',
          startAt: checkOut,
          endAt: checkOut.add(const Duration(hours: 1)),
          status: json['status'] ?? 'CONFIRMED',
          color: '#D4A574',
          sourceModule: 'reservations',
        ));
      }

      if (fromDate != null) {
        items.removeWhere((item) => item.startAt.isBefore(fromDate));
      }
      if (toDate != null) {
        items.removeWhere((item) => item.startAt.isAfter(toDate));
      }

      items.sort((a, b) => a.startAt.compareTo(b.startAt));
      return items;
    } catch (e) {
      if (kDebugMode) debugPrint('getScheduleForGuest error: $e');
      return [];
    }
  }

  Future<List<GuestScheduleItem>> getTodaysSchedule(String guestId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return getScheduleForGuest(guestId, fromDate: todayStart, toDate: tomorrowStart);
  }

  Future<bool> markItemCompleted(String itemId, {String? sourceModule}) async {
    try {
      if (sourceModule == null || sourceModule == 'guest_schedule_items') {
        final existing = await _client
            .from('guest_schedule_items')
            .select('status, eco_points_awarded')
            .eq('id', itemId)
            .maybeSingle();

        if (existing == null) {
          if (kDebugMode) debugPrint('Item not found in guest_schedule_items');
          return false;
        }
        if (existing['status'] == 'COMPLETED') {
          if (kDebugMode) debugPrint('Item already completed');
          return false;
        }

        final updated = await _client
            .from('guest_schedule_items')
            .update({
              'status': 'COMPLETED',
              'completed_at': DateTime.now().toUtc().toIso8601String(),
              'eco_points_awarded': true,
            })
            .eq('id', itemId)
            .select('status')
            .maybeSingle();

        if (updated == null || updated['status'] != 'COMPLETED') {
          if (kDebugMode) debugPrint('Failed to update item status in DB');
          return false;
        }
        return true;
      }

      switch (sourceModule) {
        case 'activity_bookings':
          final booking = await _client
              .from('activity_bookings')
              .select('status')
              .eq('id', itemId)
              .maybeSingle();
          if (booking == null) {
            if (kDebugMode) debugPrint('Activity booking not found');
            return false;
          }
          if (booking['status'] == 'COMPLETED') {
            if (kDebugMode) debugPrint('Activity booking already completed');
            return false;
          }
          final updated = await _client
              .from('activity_bookings')
              .update({'status': 'COMPLETED'})
              .eq('id', itemId)
              .select('status')
              .maybeSingle();
          if (updated == null || updated['status'] != 'COMPLETED') {
            if (kDebugMode) debugPrint('Failed to update activity booking status in DB');
            return false;
          }
          return true;
        case 'food_orders':
          await _client
              .from('food_orders')
              .update({'status': 'SERVED'})
              .eq('id', itemId);
          return true;
        default:
          final updated = await _client
              .from('guest_schedule_items')
              .update({
                'status': 'COMPLETED',
                'completed_at': DateTime.now().toUtc().toIso8601String(),
                'eco_points_awarded': true,
              })
              .eq('id', itemId)
              .select('status')
              .maybeSingle();
          if (updated == null || updated['status'] != 'COMPLETED') {
            if (kDebugMode) debugPrint('Failed to update default item status');
            return false;
          }
          return true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('markItemCompleted error: $e');
      return false;
    }
  }

  Future<List<GuestScheduleItem>> autoCompleteOverdueItems(String guestId) async {
    try {
      return _client.rpc('auto_complete_schedule_items').then((_) async {
        return getScheduleForGuest(guestId);
      }).catchError((_) async {
        await _manualAutoComplete(guestId);
        return getScheduleForGuest(guestId);
      });
    } catch (e) {
      await _manualAutoComplete(guestId);
      return getScheduleForGuest(guestId);
    }
  }

  Future<void> _manualAutoComplete(String guestId) async {
    try {
      final now = DateTime.now().toUtc();
      final overdueItems = await _client
          .from('guest_schedule_items')
          .select('id, guest_id, title, status, end_at, eco_points_awarded')
          .eq('guest_id', guestId)
          .neq('status', 'COMPLETED')
          .neq('status', 'CANCELLED');

      for (final item in overdueItems) {
        final endAt = item['end_at'] != null ? DateTime.parse(item['end_at']) : null;
        if (endAt == null) continue;
        if (now.isBefore(endAt.add(const Duration(minutes: 5)))) continue;

        await _client
            .from('guest_schedule_items')
            .update({
              'status': 'COMPLETED',
              'completed_at': now.toIso8601String(),
              'eco_points_awarded': true,
            })
            .eq('id', item['id']);

        if (item['eco_points_awarded'] != true) {
          await _client.from('guest_eco_point_events').insert({
            'guest_id': guestId,
            'source_type': 'SCHEDULE',
            'source_record_id': item['id'] ?? '',
            'source_label': 'Completed scheduled activity: ${item['title']}',
            'points': 25,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('_manualAutoComplete error: $e');
    }
  }
}
