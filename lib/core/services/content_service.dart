import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/site_content_page.dart';
import '../models/hotel_service.dart';
import '../models/hotel_service_category.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<SiteContentPage?> getPage(String slug) async {
    try {
      final response = await _client
          .from('site_content_pages')
          .select('*')
          .eq('slug', slug)
          .eq('is_active', true)
          .maybeSingle();
      return response != null ? SiteContentPage.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<List<HotelServiceCategory>> getServiceCategories() async {
    try {
      final response = await _client
          .from('hotel_service_categories')
          .select('*')
          .eq('is_active', true)
          .order('display_order');
      return response.map((e) => HotelServiceCategory.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<HotelService>> getHotelServices() async {
    try {
      final response = await _client
          .from('hotel_services')
          .select('*')
          .eq('is_available', true)
          .order('sort_order');
      return response.map((e) => HotelService.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

}
