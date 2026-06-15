import 'package:flutter/material.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/food_service.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/models/food_order.dart';
import '../../../core/theme/app_theme.dart';

class FoodBeverageScreen extends StatefulWidget {
  const FoodBeverageScreen({super.key});

  @override
  State<FoodBeverageScreen> createState() => _FoodBeverageScreenState();
}

class _FoodBeverageScreenState extends State<FoodBeverageScreen> {
  List<MenuItem> _menuItems = [];
  List<FoodOrder> _orders = [];
  bool _isLoading = true;

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
    final items = await FoodService().getMenuItems();
    if (mounted) {
      setState(() => _menuItems = items);
    }
  }

  Future<void> _loadOrders() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) return;

    final orders = await FoodService().getMyOrders(guestId);
    if (mounted) {
      setState(() => _orders = orders);
    }
  }

  Future<void> _placeOrder(MenuItem item, int quantity) async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) return;

    // Get room ID from active reservation
    final guest = await GuestService().getCurrentGuest();
    final roomId = guest?.reservations?.isNotEmpty == true 
        ? guest!.reservations![0].roomId 
        : null;

    if (roomId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active room assignment')),
        );
      }
      return;
    }

    final success = await FoodService().placeOrder(
      guestId: guestId,
      roomId: roomId,
      items: [
        {
          'name': item.name,
          'price': item.price,
          'quantity': quantity,
        }
      ],
      subtotal: item.price * quantity,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Order placed successfully!' 
              : 'Failed to place order'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
      if (success) _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Food & Beverage'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Menu', icon: Icon(Icons.menu_book)),
              Tab(text: 'My Orders', icon: Icon(Icons.receipt)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildMenuList(),
                  _buildOrdersList(),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuList() {
    if (_menuItems.isEmpty) {
      return const Center(child: Text('No menu items available'));
    }

    final categories = _menuItems.map((i) => i.category).toSet().toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = _menuItems.where((i) => i.category == category).toList();
        return _buildCategorySection(category, items);
      },
    );
  }

  Widget _buildCategorySection(String category, List<MenuItem> items) {
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

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.restaurant, color: AppTheme.primary),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: item.imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imagePath!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderImage(),
                ),
              )
            : _placeholderImage(),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          item.description ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          'Rs ${item.price}',
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

  Widget _buildOrderCard(FoodOrder order) {
    final status = order.status;
    final total = order.total;
    final orderId = order.orderId;
    final createdAt = order.createdAt ?? DateTime.now();

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
              'Placed on ${createdAt.day}/${createdAt.month}/${createdAt.year}',
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

  void _showOrderDialog(MenuItem item) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Order ${item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Price: Rs ${item.price}'),
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
                'Total: Rs ${(item.price) * quantity}',
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
                _placeOrder(item, quantity);
              },
              child: const Text('Order'),
            ),
          ],
        ),
      ),
    );
  }
}








