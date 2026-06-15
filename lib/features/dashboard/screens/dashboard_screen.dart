import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_button.dart';
import '../../schedule/screens/daily_schedule_screen.dart';
import '../../activities/screens/activities_screen.dart';
import '../../food/screens/food_beverage_screen.dart';
import '../../payments/screens/payments_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../messages/screens/messages_screen.dart';

/// Dashboard Screen - Main home screen showing guest overview
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _guestData;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  int _unreadMessages = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final guest = await SupabaseService.getCurrentGuest();
    if (mounted) {
      setState(() {
        _guestData = guest;
        _isLoading = false;
      });
      _loadUnreadCounts();
    }
  }

  Future<void> _loadUnreadCounts() async {
    // Load unread notifications and messages count
    // This would be implemented with actual queries
    setState(() {
      _unreadNotifications = 2;
      _unreadMessages = 1;
    });
  }

  String get _guestName {
    final firstName = _guestData?['first_name'] ?? '';
    final lastName = _guestData?['last_name'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return 'Guest';
  }

  String get _roomNumber {
    final reservations = _guestData?['reservations'];
    if (reservations != null && reservations is List && reservations.isNotEmpty) {
      final room = reservations[0]['rooms'];
      if (room != null) {
        return room['room_number']?.toString() ?? '--';
      }
    }
    return '--';
  }

  String get _roomType {
    final reservations = _guestData?['reservations'];
    if (reservations != null && reservations is List && reservations.isNotEmpty) {
      final room = reservations[0]['rooms'];
      if (room != null) {
        return room['type']?.toString() ?? '';
      }
    }
    return '';
  }

  String get _checkInDate {
    final reservations = _guestData?['reservations'];
    if (reservations != null && reservations is List && reservations.isNotEmpty) {
      return reservations[0]['check_in'] ?? '';
    }
    return '';
  }

  String get _checkOutDate {
    final reservations = _guestData?['reservations'];
    if (reservations != null && reservations is List && reservations.isNotEmpty) {
      return reservations[0]['check_out'] ?? '';
    }
    return '';
  }

  String get _reservationStatus {
    final reservations = _guestData?['reservations'];
    if (reservations != null && reservations is List && reservations.isNotEmpty) {
      return reservations[0]['status'] ?? 'CONFIRMED';
    }
    return 'CONFIRMED';
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar with Welcome
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryLight,
                          ],
                        ),
                      ),
                    ),
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          _guestName,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () => _navigateTo(const NotificationsScreen()),
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppTheme.accentRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _unreadNotifications.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message_outlined),
                          onPressed: () => _navigateTo(const MessagesScreen()),
                        ),
                        if (_unreadMessages > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppTheme.accentRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _unreadMessages.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                // Room Info Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DashboardCard(
                      title: 'Current Stay',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.hotel,
                                  color: AppTheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Room $_roomNumber',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (_roomType.isNotEmpty)
                                      Text(
                                        _roomType,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor().withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _reservationStatus,
                                  style: TextStyle(
                                    color: _getStatusColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateInfo(
                                  'Check-in',
                                  _checkInDate,
                                  Icons.login,
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: AppTheme.borderLight,
                              ),
                              Expanded(
                                child: _buildDateInfo(
                                  'Check-out',
                                  _checkOutDate,
                                  Icons.logout,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.calendar_today,
                                label: 'Schedule',
                                color: AppTheme.primary,
                                onTap: () => _navigateTo(const DailyScheduleScreen()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.explore,
                                label: 'Activities',
                                color: AppTheme.secondary,
                                onTap: () => _navigateTo(const ActivitiesScreen()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.restaurant,
                                label: 'Dining',
                                color: AppTheme.accentOrange,
                                onTap: () => _navigateTo(const FoodBeverageScreen()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.receipt_long,
                                label: 'Bills',
                                color: AppTheme.accentGreen,
                                onTap: () => _navigateTo(const PaymentsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Today's Activities
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DashboardCard(
                      title: 'Today\'s Highlights',
                      child: Column(
                        children: [
                          _buildHighlightItem(
                            icon: Icons.wb_sunny,
                            iconColor: AppTheme.accentOrange,
                            title: 'Weather',
                            subtitle: 'Sunny, 28°C',
                          ),
                          const Divider(),
                          _buildHighlightItem(
                            icon: Icons.event,
                            iconColor: AppTheme.primary,
                            title: 'Next Activity',
                            subtitle: 'Beach Yoga at 8:00 AM',
                          ),
                          const Divider(),
                          _buildHighlightItem(
                            icon: Icons.local_offer,
                            iconColor: AppTheme.secondary,
                            title: 'Special Offer',
                            subtitle: '20% off Spa treatments today',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
    );
  }

  Widget _buildDateInfo(String label, String date, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date.isNotEmpty ? _formatDate(date) : '--',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_reservationStatus.toUpperCase()) {
      case 'CHECKED_IN':
        return AppTheme.statusConfirmed;
      case 'CONFIRMED':
        return AppTheme.statusPending;
      case 'CHECKED_OUT':
        return AppTheme.textSecondary;
      default:
        return AppTheme.statusPending;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }
}
