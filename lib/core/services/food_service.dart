import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';

class FoodService {
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;
  FoodService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await _client
          .from('menu_items')
          .select('*')
          .eq('is_available', true)
          .order('category');
      return response.map((e) => MenuItem.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('getMenuItems error: $e');
      return [];
    }
  }
}
