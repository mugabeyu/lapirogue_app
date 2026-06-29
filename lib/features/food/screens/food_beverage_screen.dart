import 'package:flutter/material.dart';
import '../../../core/services/food_service.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/theme/app_theme.dart';

class FoodBeverageScreen extends StatefulWidget {
  const FoodBeverageScreen({super.key});

  @override
  State<FoodBeverageScreen> createState() => _FoodBeverageScreenState();
}

class _FoodBeverageScreenState extends State<FoodBeverageScreen> {
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    final items = await FoodService().getMenuItems();
    if (mounted) {
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food & Beverage'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMenuList(),
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

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: item.imagePath != null
                ? Image.network(
                    item.imagePath!,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 96,
                      height: 96,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.restaurant, color: AppTheme.primary),
                    ),
                  )
                : Container(
                    width: 96,
                    height: 96,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.restaurant, color: AppTheme.primary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Rs ${item.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.timer, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${item.preparationMinutes} min',
                        style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
