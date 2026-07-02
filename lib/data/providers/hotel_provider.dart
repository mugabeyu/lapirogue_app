import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/room.dart';
import '../../core/models/activity.dart';
import '../../core/models/menu_item.dart';

final allRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final response = await Supabase.instance.client
      .from('rooms')
      .select('*')
      .order('room_number');

  return (response as List).map((e) => Room.fromJson(e)).toList();
});

final featuredRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final response = await Supabase.instance.client
      .from('rooms')
      .select('*')
      .eq('status', 'AVAILABLE')
      .inFilter('type', ['SUITE', 'VILLA'])
      .order('price', ascending: true)
      .limit(5);

  return (response as List).map((e) => Room.fromJson(e)).toList();
});

final roomByIdProvider = FutureProvider.family<Room?, String>((ref, id) async {
  final response = await Supabase.instance.client
      .from('rooms')
      .select('*')
      .eq('id', id)
      .maybeSingle();

  if (response == null) return null;
  return Room.fromJson(response);
});

final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final response = await Supabase.instance.client
      .from('activities')
      .select('*')
      .eq('status', 'ACTIVE')
      .order('name');

  return (response as List).map((e) => Activity.fromJson(e)).toList();
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) async {
  final response = await Supabase.instance.client
      .from('menu_items')
      .select('*')
      .eq('is_available', true)
      .order('category');

  return (response as List).map((e) => MenuItem.fromJson(e)).toList();
});


