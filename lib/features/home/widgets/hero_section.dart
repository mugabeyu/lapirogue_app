import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/providers/notifications_provider.dart';

/// Minimal, reference-matching home header: "Bonjour, {name}" greeting on
/// the left, notification bell (with unread badge) on the right.
class HeroSection extends ConsumerWidget {
  final String? firstName;

  const HeroSection({
    super.key,
    this.firstName,
    this.greeting = '',
    this.location = '',
    this.temperature = '',
    this.weatherCondition = '',
  });

  // Kept for backward-compat with call sites; no longer rendered.
  final String greeting;
  final String location;
  final String temperature;
  final String weatherCondition;

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    if (hour < 21) return 'Good evening,';
    return 'Good night,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = firstName ?? 'Guest';
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (items) => items.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/lapirogue_logo.jpg',
                    height: 28,
                    width: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'La Pirogue Hotel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeGreeting(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.lightGray2),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
