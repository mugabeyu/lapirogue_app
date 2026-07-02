import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reservation_gate.dart';
import '../../../core/models/menu_item.dart';

class DiningScreen extends ConsumerStatefulWidget {
  const DiningScreen({super.key});

  @override
  ConsumerState<DiningScreen> createState() => _DiningScreenState();
}

class _DiningScreenState extends ConsumerState<DiningScreen> {
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

  Future<void> _placeOrder(MenuItem item, int quantity, String notes) async {
    final guest = await SessionService.getCurrentGuest();
    if (guest == null) {
      throw Exception('Please sign in to place an order.');
    }

    final subtotal = item.price * quantity;
    final baseUrl = await AuthService().baseUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/api/food-orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'guestId': guest['id'].toString(),
        'items': [
          {
            'id': item.id,
            'name': item.name,
            'quantity': quantity,
            'price': item.price,
          },
        ],
        'subtotal': subtotal,
        'serviceCharge': 0,
        'taxAmount': 0,
        'total': subtotal,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
        'origin': 'MOBILE_APP',
      }),
    );

    if (response.statusCode >= 400) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(payload['error'] ?? 'Unable to place order');
    }
  }

  Future<void> _showOrderSheet(MenuItem item) async {
    final notesController = TextEditingController();
    var quantity = 1;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final total = item.price * quantity;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(item.name, style: AppTypography.sectionHeader),
                    const SizedBox(height: 6),
                    Text(
                      item.description?.trim().isNotEmpty == true
                          ? item.description!
                          : 'Prepared fresh by our culinary team.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Quantity',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setSheetState(() => quantity -= 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$quantity', style: AppTypography.bodyBold),
                        IconButton(
                          onPressed: () => setSheetState(() => quantity += 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Special instructions',
                        hintText:
                            'No onions, extra spicy, deliver after 8 PM...',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: AppTypography.bodyBold),
                        Text(
                          'MUR ${total.toStringAsFixed(0)}',
                          style: AppTypography.priceSmall.copyWith(
                            color: AppColors.oceanBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _placeOrder(
                                    item,
                                    quantity,
                                    notesController.text,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(this.context).pop();
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${item.name} ordered successfully.',
                                      ),
                                      backgroundColor:
                                          AppColors.statusConfirmed,
                                    ),
                                  );
                                } catch (error) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor:
                                            AppColors.statusCancelled,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.oceanBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          isSubmitting ? 'Placing order...' : 'Order now',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReservationGate(
      requiresCheckIn: true,
      checkInLockedTitle: 'Dining Available After Check-In',
      checkInLockedMessage:
          'Our restaurant menus will be available once you check in.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dining'),
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: Colors.white,
        ),
        backgroundColor: AppColors.surfaceLight,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _menuItems.isEmpty
            ? const Center(child: Text('No menu items available'))
            : RefreshIndicator(
                onRefresh: _loadMenu,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.goldAccent,
                                AppColors.oceanBlue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dining at your fingertips',
                                style: AppTypography.sectionHeader.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore the full menu by category, review images and descriptions, and place in-stay orders once you are checked in.',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _DiningStatPill(
                                    label: '${_menuItems.length} items',
                                    icon: Icons.restaurant_menu,
                                  ),
                                  _DiningStatPill(
                                    label:
                                        '${_categories.length - 1} categories',
                                    icon: Icons.category_outlined,
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
                                    : AppColors.oceanBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.oceanBlue,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.oceanBlue
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
                                style: AppTypography.sectionHeaderSmall,
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
                                  child: _DiningCard(
                                    item: item,
                                    onOrder: () => _showOrderSheet(item),
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

class _DiningCard extends StatelessWidget {
  const _DiningCard({required this.item, required this.onOrder});

  final MenuItem item;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                          _DiningFallback(category: item.category),
                    )
                  : _DiningFallback(category: item.category),
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
                        style: AppTypography.sectionHeaderSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MUR ${item.price.toStringAsFixed(0)}',
                      style: AppTypography.priceSmall.copyWith(
                        color: AppColors.oceanBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description?.trim().isNotEmpty == true
                      ? item.description!
                      : 'Crafted by our culinary team with fresh resort ingredients.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DiningMetaChip(
                      icon: Icons.category_outlined,
                      label: item.category,
                    ),
                    _DiningMetaChip(
                      icon: Icons.timer_outlined,
                      label: '${item.preparationMinutes} min',
                    ),
                    _DiningMetaChip(
                      icon: item.isAvailable
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
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
                      backgroundColor: AppColors.oceanBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      item.isAvailable
                          ? 'Order this item'
                          : 'Currently unavailable',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sandBeige, AppColors.lightGray],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _iconForCategory(category),
          size: 52,
          color: AppColors.oceanBlue.withValues(alpha: 0.55),
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

class _DiningMetaChip extends StatelessWidget {
  const _DiningMetaChip({required this.icon, required this.label});

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
          Icon(icon, size: 15, color: AppColors.oceanBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionSmallBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiningStatPill extends StatelessWidget {
  const _DiningStatPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

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
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionSmallBold.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
