import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

/// Food & Beverage Screen
class FoodBeverageScreen extends StatefulWidget {
  const FoodBeverageScreen({super.key});

  @override
  State<FoodBeverageScreen> createState() => _FoodBeverageScreenState();
}

class _FoodBeverageScreenState extends State<FoodBeverageScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMenuItems(),
      _loadOrders(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMenuItems() async {
    try {
      final response = await SupabaseService.client
          .from('menu_items')
          .select('*')
          .eq('is_available', true)
          .order('category');
      setState(() => _menuItems = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading menu: $e');
    }
  }

  Future<void> _loadOrders() async {
    final guestId = await SupabaseService.getCurrentGuestId();
    if (guestId == null) return;

    try {
      final response = await SupabaseService.client
          .from('food_orders')
          .select('*')
          .eq('guest_id', guestId)
          .order('created_at', ascending: false);
      setState(() => _orders = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food & Beverage'),
        bottom: TabBar(
          controller: TabController(length: 2, vsync: Navigator.of(context)),
          tabs: const [
            Tab(text: 'Menu', icon: Icon(Icons.menu_book)),
            Tab(text: 'My Orders', icon: Icon(Icons.receipt)),
          ],
          onTap: (index) => setState(() => _selectedTab = index),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTab == 0
              ? _buildMenuList()
              : _buildOrdersList(),
    );
  }

  Widget _buildMenuList() {
    if (_menuItems.isEmpty) {
      return const Center(child: Text('No menu items available'));
    }

    final categories = _menuItems.map((i) => i['category'] as String).toSet().toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = _menuItems.where((i) => i['category'] == category).toList();
        return _buildCategorySection(category, items);
      },
    );
  }

  Widget _buildCategorySection(String category, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildMenuItemCard(item)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: item['image_path'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image_path'],
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: AppTheme.primary),
              ),
        title: Text(
          item['name'] ?? 'Unnamed Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item['description'] ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          'Rs ${item['price'] ?? 0}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primary,
          ),
        ),
        onTap: () => _showOrderDialog(item),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final total = order['total'] ?? 0;
    final orderId = order['order_id'] ?? 'Unknown';
    final createdAt = DateTime.parse(order['created_at'] ?? DateTime.now().toIso8601String());

    Color statusColor;
    switch (status.toUpperCase()) {
      case 'SERVED':
      case 'COMPLETED':
        statusColor = AppTheme.accentGreen;
        break;
      case 'PREPARING':
        statusColor = AppTheme.accentOrange;
        break;
      case 'CANCELLED':
        statusColor = AppTheme.accentRed;
        break;
      default:
        statusColor = AppTheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Placed on ${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Rs ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDialog(Map<String, dynamic> item) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Order ${item['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Price: Rs ${item['price']}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () => setDialogState(() => quantity--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => setDialogState(() => quantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: Rs ${(item['price'] ?? 0) * quantity}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ordered ${item['name']} x$quantity')),
                );
              },
              child: const Text('Order'),
            ),
          ],
        ),
      ),
    );
  }
}
