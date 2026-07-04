import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reservation_gate.dart';
import '../../../core/models/menu_item.dart';
import '../../booking/screens/booking_screen.dart';

class RoomServiceScreen extends ConsumerStatefulWidget {
  const RoomServiceScreen({super.key});

  @override
  ConsumerState<RoomServiceScreen> createState() => _RoomServiceScreenState();
}

class _RoomServiceScreenState extends ConsumerState<RoomServiceScreen> {
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMenu();
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
    context.push(
      '/booking',
      extra: BookingItem(
        type: BookingType.roomService,
        id: item.id,
        name: item.name,
        imagePath: item.imagePath,
        price: item.price,
        category: item.category,
        description: item.description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReservationGate(
      requiresCheckIn: true,
      checkInLockedTitle: 'Room Service Available After Check-In',
      checkInLockedMessage:
          'You can order room service once you check in at the hotel.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Room Service'),
          backgroundColor: AppColors.darkNavy,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: () => context.push('/orders'),
              icon: const Icon(Icons.receipt_outlined, size: 18, color: Colors.white),
              label: const Text(
                'My Orders',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadMenu,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.goldAccent,
                                AppColors.darkNavy,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room Service',
                                style: AppTypography.sectionTitle.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Order food and beverages delivered to your room.',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _StatPill(
                                    label: '${_menuItems.length} items',
                                    icon: Icons.restaurant_menu,
                                    color: Colors.white,
                                  ),
                                  _StatPill(
                                    label: '${_categories.length - 1} categories',
                                    icon: Icons.category_outlined,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 64,
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
                                color: selected
                                    ? Colors.white
                                    : AppColors.darkNavy,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.darkNavy,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.darkNavy
                                    : AppColors.lightGray2,
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
                              Text(
                                entry.key,
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${entry.value.length} ${entry.value.length == 1 ? 'dish' : 'dishes'} available',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...entry.value.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _MenuCard(
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onOrder});

  final MenuItem item;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOrder,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: SizedBox(
              height: 184,
              width: double.infinity,
              child: item.imagePath != null && item.imagePath!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imagePath!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: AppColors.lightGray),
                      errorWidget: (_, _, _) =>
                          _Fallback(category: item.category),
                    )
                  : _Fallback(category: item.category),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MUR ${item.price.toStringAsFixed(0)}',
                      style: AppTypography.priceSmall.copyWith(
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description?.trim().isNotEmpty == true
                      ? item.description!
                      : 'Delivered fresh to your room.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: item.category,
                    ),
                    _MetaChip(
                      icon: Icons.timer_outlined,
                      label: '${item.preparationMinutes} min',
                    ),
                    _MetaChip(
                      icon: Icons.check_circle_outline,
                      label: item.isAvailable ? 'Available now' : 'Unavailable',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: item.isAvailable ? onOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      item.isAvailable
                          ? 'Order to Room'
                          : 'Currently unavailable',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.goldAccentLight, AppColors.lightGray],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _iconForCategory(category),
          size: 52,
          color: AppColors.darkNavy.withValues(alpha: 0.55),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.darkNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
