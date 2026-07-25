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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Room Service'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => context.push('/orders'),
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'My Orders',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadMenu,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 56,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                                  child: _RoomServiceCard(
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

class _RoomServiceCard extends StatelessWidget {
  const _RoomServiceCard({required this.item, required this.onOrder});

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
                        errorWidget: (_, _, _) => _Fallback(category: item.category),
                      )
                    : _Fallback(category: item.category),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    item.description?.trim().isNotEmpty == true
                        ? item.description!
                        : 'Delivered fresh to your room.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !item.isAvailable ? 'Currently unavailable' : '${item.preparationMinutes} min prep',
                    style: AppTypography.small.copyWith(color: !item.isAvailable ? AppColors.statusCancelled : AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('MUR ${item.price.toStringAsFixed(0)}', style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700)),
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

class _Fallback extends StatelessWidget {
  const _Fallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: Icon(_iconForCategory(category), size: 26, color: AppColors.primary.withValues(alpha: 0.55)),
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
