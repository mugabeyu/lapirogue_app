import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../activities/screens/activities_screen.dart';
import '../../food/screens/food_beverage_screen.dart';
import '../../schedule/screens/daily_schedule_screen.dart';
import '../../hotel_info/screens/hotel_info_screen.dart';
import '../../sustainability/screens/sustainability_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../feedback/screens/feedback_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const List<_ExploreItem> _items = [
    _ExploreItem(
      icon: Icons.explore,
      label: 'Activities & Tours',
      subtitle: 'Book excursions and activities',
      color: AppTheme.primary,
    ),
    _ExploreItem(
      icon: Icons.restaurant,
      label: 'Food & Beverage',
      subtitle: 'Order food and drinks',
      color: AppTheme.accentOrange,
    ),
    _ExploreItem(
      icon: Icons.calendar_today,
      label: 'Daily Schedule',
      subtitle: 'View your daily itinerary',
      color: AppTheme.secondary,
    ),
    _ExploreItem(
      icon: Icons.info_outline,
      label: 'Hotel Information',
      subtitle: 'About La Pirogue and services',
      color: AppTheme.primaryLight,
    ),
    _ExploreItem(
      icon: Icons.eco,
      label: 'Sustainability',
      subtitle: 'Eco points and rewards',
      color: AppTheme.accentGreen,
    ),
    _ExploreItem(
      icon: Icons.notifications_outlined,
      label: 'Notifications',
      subtitle: 'View your notifications',
      color: AppTheme.accentPurple,
    ),
    _ExploreItem(
      icon: Icons.feedback_outlined,
      label: 'Feedback',
      subtitle: 'Share your experience',
      color: AppTheme.textSecondary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discover La Pirogue',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Everything you need for a perfect stay',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildGridItem(context, _items[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, _ExploreItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigate(context, item.label),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String label) {
    final screen = _getScreen(label);
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  Widget? _getScreen(String label) {
    switch (label) {
      case 'Activities & Tours': return const ActivitiesScreen();
      case 'Food & Beverage': return const FoodBeverageScreen();
      case 'Daily Schedule': return const DailyScheduleScreen();
      case 'Hotel Information': return const HotelInfoScreen();
      case 'Sustainability': return const SustainabilityScreen();
      case 'Notifications': return const NotificationsScreen();
      case 'Feedback': return const FeedbackScreen();
      default: return null;
    }
  }
}

class _ExploreItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _ExploreItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });
}
