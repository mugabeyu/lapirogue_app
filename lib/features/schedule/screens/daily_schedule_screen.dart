// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/guest_schedule_item.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/reservation_provider.dart';
import 'package:intl/intl.dart';

/// Daily Schedule Screen - Shows guest schedule items in day-by-day format
/// with "Mark as Completed" button to earn eco-points.
class DailyScheduleScreen extends ConsumerStatefulWidget {
  const DailyScheduleScreen({super.key});

  @override
  ConsumerState<DailyScheduleScreen> createState() =>
      _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends ConsumerState<DailyScheduleScreen> {
  List<GuestScheduleItem> _scheduleItems = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final guest = await GuestService().getCurrentGuest();
    if (guest == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ScheduleService().autoCompleteOverdueItems(guest.id);
      final items = await ScheduleService().getScheduleForGuest(guest.id);
      setState(() {
        _scheduleItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading schedule: $e');
      setState(() => _isLoading = false);
    }
  }

  List<GuestScheduleItem> get _itemsForSelectedDate {
    return _scheduleItems.where((item) {
      return item.startAt.year == _selectedDate.year &&
          item.startAt.month == _selectedDate.month &&
          item.startAt.day == _selectedDate.day;
    }).toList();
  }

  Future<void> _markCompleted(GuestScheduleItem item) async {
    final guest = await GuestService().getCurrentGuest();
    if (guest == null) return;

    if (!ref.read(reservationProvider).isCheckedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can complete schedule items after check-in.'),
          ),
        );
      }
      return;
    }

    if (item.status.toUpperCase() == 'COMPLETED') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This activity is already completed')),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: Text(
          'Have you completed "${item.title}"? You will earn eco-points!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Complete!'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final scheduleSuccess = await ScheduleService().markItemCompleted(
      item.id,
      sourceModule: item.sourceModule,
    );

    bool pointsAwarded = false;
    if (scheduleSuccess) {
      pointsAwarded = await EcoPointsService().earnPoints(
        guestId: guest.id,
        points: 25,
        description: 'Completed scheduled activity: ${item.title}',
        sourceType: 'SCHEDULE',
        sourceRecordId: item.id,
      );
    }

    if (mounted) {
      setState(() {
        for (int i = 0; i < _scheduleItems.length; i++) {
          if (_scheduleItems[i].id == item.id) {
            _scheduleItems[i] = GuestScheduleItem(
              id: item.id,
              guestId: item.guestId,
              title: item.title,
              itemType: item.itemType,
              startAt: item.startAt,
              endAt: item.endAt,
              location: item.location,
              description: item.description,
              status: 'COMPLETED',
              color: item.color,
              sourceModule: item.sourceModule,
              notes: item.notes,
            );
          }
        }
      });

      if (pointsAwarded) {
        _showEcoPointsAnimation();
      } else if (scheduleSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity marked but failed to award eco-points'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item already completed or failed to update'),
          ),
        );
      }
    }
  }

  void _showEcoPointsAnimation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '+25 Eco-Points!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Keep up the great work!',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Schedule')),
        body: const Center(child: Text('Sign in to view your schedule')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(
                              const Duration(days: 1),
                            );
                          });
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            DateFormat('EEEE').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(
                              const Duration(days: 1),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _itemsForSelectedDate.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 64,
                                color: AppTheme.textTertiary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities scheduled',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _itemsForSelectedDate.length,
                          itemBuilder: (context, index) {
                            final item = _itemsForSelectedDate[index];
                            return _buildScheduleItem(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildScheduleItem(GuestScheduleItem item) {
    final startAt = item.startAt;
    final endAt = item.endAt;
    final title = item.title;
    final description = item.description ?? '';
    final location = item.location ?? '';
    final status = item.status;
    final isCompleted = status.toUpperCase() == 'COMPLETED';
    final canComplete = ref.watch(reservationProvider).isCheckedIn;
    final isFinished = DateTime.now().isAfter(endAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.accentGreen.withValues(alpha: 0.1)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('HH:mm').format(startAt),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppTheme.accentGreen
                          : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(endAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isCompleted) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.accentGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Marked as Completed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ] else if (canComplete &&
                        isFinished &&
                        item.sourceModule != 'reservations') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markCompleted(item),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        ),
                      ),
                    ] else if (!canComplete &&
                        isFinished &&
                        item.sourceModule != 'reservations') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text('Complete after check-in'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = AppTheme.accentGreen;
        break;
      case 'IN_PROGRESS':
        color = AppTheme.accentOrange;
        break;
      case 'CANCELLED':
        color = AppTheme.accentRed;
        break;
      default:
        color = AppTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
