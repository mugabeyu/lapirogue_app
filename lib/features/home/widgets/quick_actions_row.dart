import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Row of quick-access shortcuts to existing app sections, matching the
/// reference design's "Book a room / Order food / Activities / Messages"
/// button row on the home screen. Every destination here is an existing
/// route — this widget adds no new screens or backend calls.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (_QuickAction(icon: Icons.bed_outlined, label: 'Book a room', route: '/rooms')),
      (_QuickAction(icon: Icons.restaurant_outlined, label: 'Order food', route: '/dining')),
      (_QuickAction(icon: Icons.tour_outlined, label: 'Activities', route: '/activities')),
      (_QuickAction(icon: Icons.chat_bubble_outline, label: 'Messages', route: '/messages')),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: actions
            .map(
              (a) => Expanded(
                child: GestureDetector(
                  onTap: () => context.push(a.route),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.lightGray2),
                        ),
                        child: Icon(a.icon, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAction({required this.icon, required this.label, required this.route});
}
