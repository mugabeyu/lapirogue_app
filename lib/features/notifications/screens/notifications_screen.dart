import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_sheet.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/notifications_provider.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: AppColors.darkNavy,
          foregroundColor: Colors.white,
        ),
        body: GestureDetector(
          onTap: () => showAuthSheet(context, message: 'Sign in to view your notifications.'),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                    child: const Icon(Icons.notifications_outlined, size: 48, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Sign in to stay updated', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () async {
              final guest = authState.guest;
              if (guest != null) {
                await NotificationService().markAllAsRead(guest.id);
                ref.invalidate(notificationsProvider);
              }
            },
            child: const Text('Mark All Read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ref.watch(notificationsProvider).when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                      child: const Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 16),
                    const Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('You\'ll see updates from the hotel here', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotification(notif.title, notif.message, _getCategoryIcon(notif.category), _getCategoryColor(notif.category), _formatTime(notif.createdAt), notif.isRead, () async {
                if (!notif.isRead) {
                  await NotificationService().markAsRead(notif.id);
                  ref.invalidate(notificationsProvider);
                }
              });
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading notifications: $e')),
      ),
    );
  }

  Widget _buildNotification(String title, String body, IconData icon, Color color, String time, bool isRead, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.darkNavy.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: isRead ? null : Border.all(color: AppColors.darkNavy.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isRead ? AppColors.textSecondary : AppColors.textPrimary)),
                      Text(time, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'message':
        return Icons.chat;
      case 'reservation':
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'offer':
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'message':
        return AppColors.darkNavy;
      case 'reservation':
      case 'booking':
        return AppColors.statusConfirmed;
      case 'payment':
        return AppColors.statusPending;
      case 'offer':
      case 'promotion':
        return AppColors.goldAccent;
      case 'alert':
      case 'warning':
        return AppColors.statusCancelled;
      default:
        return AppColors.statusInfo;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
