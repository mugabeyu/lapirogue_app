import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/reservation_gate.dart';

class RoomServiceScreen extends ConsumerWidget {
  const RoomServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReservationGate(
      requiresCheckIn: true,
      checkInLockedTitle: 'Room Service Available After Check-In',
      checkInLockedMessage: 'You can order room service once you check in at the hotel.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Room Service'),
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Quick Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildCategoryCard('Breakfast', Icons.free_breakfast, const Color(0xFFF59E0B), [
              'Continental Breakfast', 'Full English', 'Fresh Fruits', 'Pastries',
            ]),
            _buildCategoryCard('Drinks', Icons.local_bar, const Color(0xFF9C27B0), [
              'Fresh Juices', 'Smoothies', 'Coffee & Tea', 'Soft Drinks',
            ]),
            _buildCategoryCard('Meals', Icons.restaurant, const Color(0xFF003B5C), [
              'Grilled Chicken', 'Pasta', 'Caesar Salad', 'Club Sandwich',
            ]),
            _buildCategoryCard('Desserts', Icons.cake, const Color(0xFFE91E63), [
              'Chocolate Cake', 'Ice Cream', 'Fruit Platter', 'Crème Brûlée',
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: items.map((item) => ListTile(
          title: Text(item, style: const TextStyle(fontSize: 14)),
          trailing: Text('MUR ${(item.length * 150 + 200).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.oceanBlue)),
          contentPadding: const EdgeInsets.only(left: 72, right: 16),
        )).toList(),
      ),
    );
  }
}
