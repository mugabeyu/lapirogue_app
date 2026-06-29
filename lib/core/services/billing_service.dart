import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingSummary {
  final double totalCharges;
  final double totalPaid;
  final double balanceDue;
  final String status;
  final List<BillingItem> items;
  final Map<String, double> totals;

  const BillingSummary({
    required this.totalCharges,
    required this.totalPaid,
    required this.balanceDue,
    required this.status,
    required this.items,
    required this.totals,
  });
}

class BillingItem {
  final String category;
  final String label;
  final double amount;
  final String? createdAt;

  const BillingItem({
    required this.category,
    required this.label,
    required this.amount,
    this.createdAt,
  });
}

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  static SupabaseClient get _client => Supabase.instance.client;

  Future<BillingSummary> getBillingSummary(String guestId) async {
    try {
      final results = await Future.wait([
        _client
            .from('reservations')
            .select('reservation_id, total_amount, created_at')
            .eq('guest_id', guestId),
        _client
            .from('activity_bookings')
            .select('activities(name, price), participants, booking_date')
            .eq('guest_id', guestId),
        _client
            .from('food_orders')
            .select('order_id, subtotal, service_charge, tax_amount, total, created_at')
            .eq('guest_id', guestId),
        _client
            .from('payments')
            .select('amount, status')
            .eq('guest_id', guestId),
        _client
            .from('payment_extra_items')
            .select('category, label, amount, created_at')
            .eq('guest_id', guestId),
      ]);

      final reservations = results[0] as List<dynamic>;
      final activityBookings = results[1] as List<dynamic>;
      final foodOrders = results[2] as List<dynamic>;
      final payments = results[3] as List<dynamic>;
      final extraCharges = results[4] as List<dynamic>;

      final items = <BillingItem>[];
      final totals = <String, double>{
        'Room charges': 0,
        'Food & Beverage orders': 0,
        'Tours and activities': 0,
        'Transport services': 0,
        'Laundry/services': 0,
        'Additional hotel purchases': 0,
        'Taxes and service charges': 0,
      };

      for (final r in reservations) {
        final amount = (r['total_amount'] ?? 0).toDouble();
        if (amount <= 0) continue;
        totals['Room charges'] = (totals['Room charges'] ?? 0) + amount;
        items.add(BillingItem(
          category: 'Room charges',
          label: r['reservation_id'] ?? 'Reservation',
          amount: amount,
          createdAt: r['created_at'],
        ));
      }

      for (final ab in activityBookings) {
        final activity = ab['activities'];
        final price = activity != null ? (activity['price'] ?? 0).toDouble() : 0;
        final participants = (ab['participants'] ?? 1) as int;
        final amount = price * participants;
        if (amount <= 0) continue;
        totals['Tours and activities'] = (totals['Tours and activities'] ?? 0) + amount;
        items.add(BillingItem(
          category: 'Tours and activities',
          label: activity?['name'] ?? 'Activity booking',
          amount: amount,
          createdAt: ab['booking_date'],
        ));
      }

      for (final fo in foodOrders) {
        final subtotal = (fo['subtotal'] ?? 0).toDouble();
        final serviceCharge = (fo['service_charge'] ?? 0).toDouble();
        final taxAmount = (fo['tax_amount'] ?? 0).toDouble();
        final total = (fo['total'] ?? subtotal + serviceCharge + taxAmount).toDouble();

        if (subtotal > 0) {
          totals['Food & Beverage orders'] = (totals['Food & Beverage orders'] ?? 0) + subtotal;
          items.add(BillingItem(
            category: 'Food & Beverage orders',
            label: '${fo['order_id']} subtotal',
            amount: subtotal,
            createdAt: fo['created_at'],
          ));
        }
        if (serviceCharge > 0) {
          totals['Taxes and service charges'] = (totals['Taxes and service charges'] ?? 0) + serviceCharge;
          items.add(BillingItem(
            category: 'Taxes and service charges',
            label: '${fo['order_id']} service charge',
            amount: serviceCharge,
            createdAt: fo['created_at'],
          ));
        }
        if (taxAmount > 0) {
          totals['Taxes and service charges'] = (totals['Taxes and service charges'] ?? 0) + taxAmount;
          items.add(BillingItem(
            category: 'Taxes and service charges',
            label: '${fo['order_id']} tax',
            amount: taxAmount,
            createdAt: fo['created_at'],
          ));
        }
        if (total > 0 && subtotal <= 0 && serviceCharge <= 0 && taxAmount <= 0) {
          totals['Food & Beverage orders'] = (totals['Food & Beverage orders'] ?? 0) + total;
          items.add(BillingItem(
            category: 'Food & Beverage orders',
            label: fo['order_id'] ?? 'Food order',
            amount: total,
            createdAt: fo['created_at'],
          ));
        }
      }

      for (final ec in extraCharges) {
        final amount = (ec['amount'] ?? 0).toDouble();
        if (amount <= 0) continue;
        final category = ec['category'] as String? ?? 'Additional hotel purchases';
        totals[category] = (totals[category] ?? 0) + amount;
        items.add(BillingItem(
          category: category,
          label: ec['label'] ?? 'Extra charge',
          amount: amount,
          createdAt: ec['created_at'],
        ));
      }

      final totalCharges = totals.values.fold<double>(0, (sum, v) => sum + v);
      double totalPaid = 0;
      for (final p in payments) {
        final amount = (p['amount'] ?? 0).toDouble();
        final status = p['status'] ?? 'PENDING';
        if (status == 'REFUNDED') {
          totalPaid -= amount;
        } else if (status != 'PENDING') {
          totalPaid += amount;
        }
      }
      final balanceDue = (totalCharges - totalPaid).clamp(0.0, double.infinity);

      String status;
      if (totalCharges == 0) {
        status = 'PENDING';
      } else if (balanceDue == 0 && totalPaid > 0) {
        status = 'PAID';
      } else if (totalPaid > 0) {
        status = 'PARTIALLY_PAID';
      } else {
        status = 'PENDING';
      }

      return BillingSummary(
        totalCharges: totalCharges,
        totalPaid: totalPaid,
        balanceDue: balanceDue,
        status: status,
        items: items,
        totals: totals,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('getBillingSummary error: $e');
      return BillingSummary(
        totalCharges: 0,
        totalPaid: 0,
        balanceDue: 0,
        status: 'PENDING',
        items: [],
        totals: {},
      );
    }
  }
}
