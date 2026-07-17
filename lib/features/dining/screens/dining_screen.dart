import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reservation_gate.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/models/food_order.dart';
import '../../../core/services/session_service.dart';
import '../../booking/screens/booking_screen.dart';

class DiningScreen extends ConsumerStatefulWidget {
  const DiningScreen({super.key});

  @override
  ConsumerState<DiningScreen> createState() => _DiningScreenState();
}

class _DiningScreenState extends ConsumerState<DiningScreen> {
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  FoodOrder? _activeOrder;
  bool _loadingActiveOrder = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _loadActiveOrder();
  }

  Future<void> _loadMenu() async {
    try {
      final response = await Supabase.instance.client
          .from('menu_items')
          .select('*')
          .eq('is_available', true)
          .order('category');

      if (mounted) {
        setState(() {
          _menuItems = (response as List)
              .map((e) => MenuItem.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActiveOrder() async {
    try {
      final guest = await SessionService.getCurrentGuest();
      if (guest == null) {
        if (mounted) setState(() => _loadingActiveOrder = false);
        return;
      }
      final response = await Supabase.instance.client
          .from('food_orders')
          .select('*')
          .eq('guest_id', guest['id'])
          .inFilter('status', ['PENDING', 'PREPARING'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _activeOrder = response != null ? FoodOrder.fromJson(response) : null;
          _loadingActiveOrder = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingActiveOrder = false);
    }
  }

  List<String> get _categories {
    final cats = _menuItems.map((m) => m.category).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'All') return _menuItems;
    return _menuItems.where((m) => m.category == _selectedCategory).toList();
  }

  Map<String, List<MenuItem>> get _groupedItems {
    final grouped = <String, List<MenuItem>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  Future<void> _orderItem(MenuItem item) async {
    if (!mounted) return;
    await context.push(
      '/booking',
      extra: BookingItem(
        type: BookingType.dining,
        id: item.id,
        name: item.name,
        imagePath: item.imagePath,
        price: item.price,
        category: item.category,
        description: item.description,
      ),
    );
    if (mounted) _loadActiveOrder();
  }

  @override
  Widget build(BuildContext context) {
    return ReservationGate(
      requiresCheckIn: true,
      checkInLockedTitle: 'Dining Available After Check-In',
      checkInLockedMessage:
          'Our restaurant menus will be available once you check in.',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Dining'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => context.push('/orders').then((_) => _loadActiveOrder()),
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'My Orders',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _menuItems.isEmpty
            ? const Center(child: Text('No menu items available'))
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadMenu();
                  await _loadActiveOrder();
                },
                child: CustomScrollView(
                  slivers: [
                    if (!_loadingActiveOrder && _activeOrder != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _ActiveOrderCard(
                            order: _activeOrder!,
                            onTap: () => context.push('/orders').then((_) => _loadActiveOrder()),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 56,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final selected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = category),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primary,
                              side: BorderSide(
                                color: selected ? AppColors.primary : AppColors.lightGray2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemCount: _categories.length,
                        ),
                      ),
                    ),
                    ..._groupedItems.entries.map(
                      (entry) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.key, style: AppTypography.cardTitle),
                              const SizedBox(height: 12),
                              ...entry.value.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DiningCard(
                                    item: item,
                                    onOrder: () => _orderItem(item),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Compact banner showing the guest's most recent in-flight food order,
/// matching the reference design's "Active order" card on the dining tab.
class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, required this.onTap});

  final FoodOrder order;
  final VoidCallback onTap;

  double get _progress {
    switch (order.status) {
      case 'PENDING':
        return 0.33;
      case 'PREPARING':
        return 0.66;
      default:
        return 1.0;
    }
  }

  Color get _statusColor {
    switch (order.status) {
      case 'PENDING':
        return AppColors.statusPending;
      case 'PREPARING':
        return AppColors.statusInfo;
      default:
        return AppColors.statusConfirmed;
    }
  }

  String get _summary {
    if (order.items.isEmpty) return 'Order #${order.orderId}';
    return order.items
        .map((i) => '${i['quantity'] ?? 1}× ${i['name'] ?? 'Item'}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active order',
              style: AppTypography.captionMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _summary,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status[0] + order.status.substring(1).toLowerCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'MUR ${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation(_statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact menu-item row matching the reference design: thumbnail, name +
/// description, price and a circular add button.
class _DiningCard extends StatelessWidget {
  const _DiningCard({required this.item, required this.onOrder});

  final MenuItem item;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.isAvailable ? onOrder : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.imagePath != null && item.imagePath!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imagePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.lightGray),
                        errorWidget: (_, _, _) => _DiningFallback(category: item.category),
                      )
                    : _DiningFallback(category: item.category),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description?.trim().isNotEmpty == true
                        ? item.description!
                        : 'Prepared fresh by our culinary team.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !item.isAvailable ? 'Currently unavailable' : '${item.preparationMinutes} min prep',
                    style: TextStyle(
                      fontSize: 11,
                      color: !item.isAvailable ? AppColors.statusCancelled : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'MUR ${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: item.isAvailable ? onOrder : null,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: item.isAvailable ? AppColors.primary : AppColors.lightGray2,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiningFallback extends StatelessWidget {
  const _DiningFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: Icon(
          _iconForCategory(category),
          size: 26,
          color: AppColors.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final value = category.toUpperCase();
    if (value.contains('DRINK') || value.contains('BEVERAGE')) {
      return Icons.local_bar_outlined;
    }
    if (value.contains('DESSERT')) return Icons.icecream_outlined;
    if (value.contains('BREAKFAST')) return Icons.free_breakfast_outlined;
    return Icons.restaurant;
  }
}
