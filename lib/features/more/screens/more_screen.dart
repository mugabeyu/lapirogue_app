import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../schedule/screens/daily_schedule_screen.dart';
import '../../activities/screens/activities_screen.dart';
import '../../food/screens/food_beverage_screen.dart';
import '../../payments/screens/payments_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../feedback/screens/feedback_screen.dart';
import '../../sustainability/screens/sustainability_screen.dart';
import '../../hotel_info/screens/hotel_info_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// More Screen - Menu with all additional features
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _guestName = 'Guest';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuestData();
  }

  Future<void> _loadGuestData() async {
    final guest = await SupabaseService.getCurrentGuest();
    if (mounted) {
      setState(() {
        final firstName = guest?['first_name'] ?? '';
        final lastName = guest?['last_name'] ?? '';
        _guestName = '$firstName $lastName'.trim();
        if (_guestName.isEmpty) _guestName = 'Guest';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
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
              title: _isLoading
                  ? const Text('More')
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          _guestName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Main Menu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMenuSection('My Stay', [
                    _MenuItem(
                      icon: Icons.calendar_today,
                      title: 'Daily Schedule',
                      subtitle: 'View your activities and events',
                      color: AppTheme.primary,
                      onTap: () => _navigateTo(const DailyScheduleScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.explore,
                      title: 'Activities & Tours',
                      subtitle: 'Book activities and excursions',
                      color: AppTheme.secondary,
                      onTap: () => _navigateTo(const ActivitiesScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.restaurant,
                      title: 'Food & Beverage',
                      subtitle: 'Order food and drinks',
                      color: AppTheme.accentOrange,
                      onTap: () => _navigateTo(const FoodBeverageScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.receipt_long,
                      title: 'Payments & Billing',
                      subtitle: 'View your bills and payments',
                      color: AppTheme.accentGreen,
                      onTap: () => _navigateTo(const PaymentsScreen()),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection('Communication', [
                    _MenuItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'View your notifications',
                      color: AppTheme.accentPurple,
                      onTap: () => _navigateTo(const NotificationsScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.message,
                      title: 'Messages',
                      subtitle: 'Chat with hotel staff',
                      color: AppTheme.primary,
                      onTap: () => _navigateTo(const MessagesScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.feedback,
                      title: 'Feedback',
                      subtitle: 'Share your experience',
                      color: AppTheme.secondary,
                      onTap: () => _navigateTo(const FeedbackScreen()),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildMenuSection('Hotel & Settings', [
                    _MenuItem(
                      icon: Icons.eco,
                      title: 'Sustainability Program',
                      subtitle: 'Eco points and rewards',
                      color: AppTheme.accentGreen,
                      onTap: () => _navigateTo(const SustainabilityScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.info,
                      title: 'Hotel Information',
                      subtitle: 'About La Pirogue and rooms',
                      color: AppTheme.primary,
                      onTap: () => _navigateTo(const HotelInfoScreen()),
                    ),
                    _MenuItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      subtitle: 'Account settings and more',
                      color: AppTheme.textSecondary,
                      onTap: () => _navigateTo(const SettingsScreen()),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textTertiary,
                    ),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 72),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}