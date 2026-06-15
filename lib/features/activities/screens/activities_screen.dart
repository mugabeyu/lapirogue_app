// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/activity_booking.dart';
import '../../../core/theme/app_theme.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<Activity> _activities = [];
  List<ActivityBooking> _myBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadActivities(),
      _loadMyBookings(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActivities() async {
    final activities = await ActivityService().getAvailableActivities();
    if (mounted) {
      setState(() => _activities = activities);
    }
  }

  Future<void> _loadMyBookings() async {
    final guestId = await SupabaseService.getCurrentGuestId();
    if (guestId == null) return;

    final bookings = await ActivityService().getMyBookings(guestId);
    if (mounted) {
      setState(() => _myBookings = bookings);
    }
  }

  Future<void> _bookActivity(Activity activity) async {
    final guestId = await SupabaseService.getCurrentGuestId();
    if (guestId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${activity.name}'),
        content: Text('Confirm booking for ${DateFormat('MMM d, yyyy').format(DateTime.now())}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ActivityService().bookActivity(
      activityId: activity.id,
      guestId: guestId,
      bookingDate: DateTime.now(),
      participants: 1,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Activity booked successfully! Eco points will be awarded.' 
              : 'Failed to book activity. Please try again.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
      if (success) _loadMyBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activities & Tours'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available', icon: Icon(Icons.explore)),
              Tab(text: 'My Bookings', icon: Icon(Icons.bookmark)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildActivitiesList(),
                  _buildBookingsList(),
                ],
              ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No activities available', style: TextStyle(color: AppTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _ActivityCard(activity: activity, onBook: () => _bookActivity(activity));
      },
    );
  }

  Widget _buildBookingsList() {
    if (_myBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No bookings yet', style: TextStyle(color: AppTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myBookings.length,
      itemBuilder: (context, index) {
        final booking = _myBookings[index];
        return _BookingCard(booking: booking);
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onBook;

  const _ActivityCard({required this.activity, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                activity.imagePath!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.duration} min',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Rs ${activity.price}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ActivityBooking booking;

  const _BookingCard({required this.booking});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return AppTheme.accentGreen;
      case 'PENDING':
        return AppTheme.accentOrange;
      case 'CANCELLED':
        return AppTheme.accentRed;
      case 'COMPLETED':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = booking.activity;
    final status = booking.status;

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
                Expanded(
                  child: Text(
                    activity?.name ?? 'Unnamed Activity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(booking.bookingDate),
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  booking.bookingTime ?? '09:00',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            if (booking.participants > 1) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.participants} participants',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

