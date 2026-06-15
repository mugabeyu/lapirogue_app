import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';
import '../models/food_order.dart';

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
      return [];
    }
  }

  Future<List<FoodOrder>> getMyOrders(String guestId) async {
    try {
      final response = await _client
          .from('food_orders')
          .select('*')
          .eq('guest_id', guestId)
          .order('created_at', ascending: false);
      return response.map((e) => FoodOrder.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> placeOrder({
    required String guestId,
    required String roomId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    double serviceCharge = 0,
    double taxAmount = 0,
    double? total,
    String? notes,
  }) async {
    try {
      final orderTotal = total ?? subtotal + serviceCharge + taxAmount;
      
      await _client.from('food_orders').insert({
        'guest_id': guestId,
        'room_id': roomId,
        'items': items,
        'subtotal': subtotal,
        'service_charge': serviceCharge,
        'tax_amount': taxAmount,
        'total': orderTotal,
        'notes': notes,
        'status': 'PENDING',
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}