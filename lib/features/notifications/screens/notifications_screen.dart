import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/notification.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final notifications = await NotificationService().getNotifications(guestId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    final success = await NotificationService().markAsRead(notification.id);
    if (success) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            guestId: notification.guestId,
            title: notification.title,
            message: notification.message,
            category: notification.category,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) return;

    final success = await NotificationService().markAllAsRead(guestId);
    if (success) {
      setState(() {
        for (var i = 0; i < _notifications.length; i++) {
          _notifications[i] = AppNotification(
            id: _notifications[i].id,
            guestId: _notifications[i].guestId,
            title: _notifications[i].title,
            message: _notifications[i].message,
            category: _notifications[i].category,
            isRead: true,
            createdAt: _notifications[i].createdAt,
          );
        }
      });
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'ACTIVITY':
        return Icons.sports;
      case 'RESERVATION':
        return Icons.hotel;
      case 'SCHEDULE':
        return Icons.calendar_today;
      case 'BILLING':
        return Icons.receipt;
      case 'EMERGENCY':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'ACTIVITY':
        return AppTheme.accentGreen;
      case 'RESERVATION':
        return AppTheme.primary;
      case 'SCHEDULE':
        return AppTheme.secondary;
      case 'BILLING':
        return AppTheme.accentOrange;
      case 'EMERGENCY':
        return AppTheme.accentRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: AppTheme.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isRead = notification.isRead;
    final category = notification.category;
    final createdAt = notification.createdAt ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, HH:mm').format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}