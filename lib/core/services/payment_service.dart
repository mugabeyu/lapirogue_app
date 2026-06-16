import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<Payment>> getPayments(String guestId) async {
    try {
      final response = await _client
          .from('payments')
          .select('*, payment_extra_items(*)')
          .eq('guest_id', guestId)
          .order('created_at', ascending: false);
      return response.map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<double> getTotalPaid(String guestId) async {
    try {
      final response = await _client
          .from('payments')
          .select('amount, status')
          .eq('guest_id', guestId);
      double total = 0;
      for (var payment in response) {
        final amount = (payment['amount'] ?? 0).toDouble();
        final status = payment['status'] ?? 'PENDING';
        if (status == 'COMPLETED' || status == 'PAID') {
          total += amount;
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<double> getTotalOutstanding(String guestId) async {
    try {
      final response = await _client
          .from('payments')
          .select('amount, status')
          .eq('guest_id', guestId);
      double total = 0;
      for (var payment in response) {
        final amount = (payment['amount'] ?? 0).toDouble();
        final status = payment['status'] ?? 'PENDING';
        if (status != 'COMPLETED' && status != 'PAID') {
          total += amount;
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
}