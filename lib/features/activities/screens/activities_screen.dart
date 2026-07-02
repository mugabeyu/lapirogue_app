import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reservation_gate.dart';
import '../../../core/models/activity.dart';
import '../../../data/providers/reservation_provider.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final response = await Supabase.instance.client
          .from('activities')
          .select('*')
          .eq('status', 'ACTIVE')
          .order('name');

      if (mounted) {
        setState(() {
          _activities = (response as List)
              .map((e) => Activity.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final values =
        _activities
            .map((activity) => activity.category.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  List<Activity> get _filteredActivities {
    if (_selectedCategory == 'All') return _activities;
    return _activities
        .where((activity) => activity.category == _selectedCategory)
        .toList();
  }

  Map<String, List<Activity>> get _groupedActivities {
    final grouped = <String, List<Activity>>{};
    for (final activity in _filteredActivities) {
      grouped.putIfAbsent(activity.category, () => []).add(activity);
    }
    return grouped;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _initialBookingDate(ReservationState reservationState) {
    final reservation = reservationState.activeReservation;
    final today = _dateOnly(DateTime.now());
    if (reservation == null) return today;
    final checkIn = _dateOnly(reservation.checkIn);
    return checkIn.isAfter(today) ? checkIn : today;
  }

  DateTime _lastBookingDate(ReservationState reservationState) {
    final reservation = reservationState.activeReservation;
    if (reservation == null) {
      return _dateOnly(DateTime.now().add(const Duration(days: 30)));
    }
    final last = _dateOnly(
      reservation.checkOut.subtract(const Duration(days: 1)),
    );
    final initial = _initialBookingDate(reservationState);
    return last.isBefore(initial) ? initial : last;
  }

  Future<void> _submitBooking(
    Activity activity,
    ReservationState reservationState,
    DateTime bookingDate,
    int participants,
  ) async {
    final guest = await SessionService.getCurrentGuest();
    if (guest == null) {
      throw Exception('Please sign in to book activities.');
    }

    final baseUrl = await AuthService().baseUrl;
    final response = await http.post(
      Uri.parse('$baseUrl/api/activities/book'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'activityId': activity.id,
        'guestId': guest['id'].toString(),
        'date': _dateOnly(bookingDate).toIso8601String().split('T').first,
        'timeSlot': activity.defaultTime ?? '09:00',
        'participants': participants,
        'status': 'CONFIRMED',
        'origin': 'MOBILE_APP',
      }),
    );

    if (response.statusCode >= 400) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(payload['error'] ?? 'Unable to book activity');
    }
  }

  Future<void> _showBookingSheet(
    Activity activity,
    ReservationState reservationState,
  ) async {
    if (!reservationState.hasActiveReservation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please make a reservation first')),
        );
      }
      return;
    }

    var selectedDate = _initialBookingDate(reservationState);
    final firstDate = selectedDate;
    final lastDate = _lastBookingDate(reservationState);
    var participants = 1;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(activity.name, style: AppTypography.sectionHeader),
                    const SizedBox(height: 6),
                    Text(
                      'Choose the day and number of guests for this experience.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_available,
                        color: AppColors.oceanBlue,
                      ),
                      title: const Text('Booking date'),
                      subtitle: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(selectedDate),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = _dateOnly(picked));
                        }
                      },
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          color: AppColors.oceanBlue,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Participants',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: participants > 1
                              ? () => setSheetState(() => participants -= 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$participants', style: AppTypography.bodyBold),
                        IconButton(
                          onPressed: participants < activity.capacity
                              ? () => setSheetState(() => participants += 1)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  await _submitBooking(
                                    activity,
                                    reservationState,
                                    selectedDate,
                                    participants,
                                  );
                                  if (!mounted) return;
                                  Navigator.of(this.context).pop();
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${activity.name} booked for ${MaterialLocalizations.of(this.context).formatMediumDate(selectedDate)}.',
                                      ),
                                      backgroundColor:
                                          AppColors.statusConfirmed,
                                    ),
                                  );
                                } catch (error) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                        backgroundColor:
                                            AppColors.statusCancelled,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.oceanBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          isSubmitting ? 'Booking...' : 'Book activity',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservationState = ref.watch(reservationProvider);

    return ReservationGate(
      requiresCheckIn: false,
      checkInLockedTitle: 'Activities Available After Check-In',
      checkInLockedMessage:
          'You can preview activities now and complete bookings against your stay dates.',
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: AppBar(
          title: const Text('Activities & Tours'),
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.oceanBlue,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activities.isEmpty
            ? const Center(child: Text('No activities available'))
            : RefreshIndicator(
                onRefresh: _loadActivities,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.oceanBlue,
                                AppColors.oceanBlueLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curated island experiences',
                                style: AppTypography.sectionHeader.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Browse every tour by category, see full details, and reserve activities against your stay dates.',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _StatPill(
                                    label: '${_activities.length} experiences',
                                    icon: Icons.tour,
                                    color: Colors.white,
                                  ),
                                  _StatPill(
                                    label:
                                        '${_categories.length - 1} categories',
                                    icon: Icons.category_outlined,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 64,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final selected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = category),
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.oceanBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.oceanBlue,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.oceanBlue
                                    : AppColors.lightGray2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemCount: _categories.length,
                        ),
                      ),
                    ),
                    ..._groupedActivities.entries.map(
                      (entry) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: AppTypography.sectionHeaderSmall
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${entry.value.length} ${entry.value.length == 1 ? 'experience' : 'experiences'} available',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...entry.value.map(
                                (activity) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ActivityCard(
                                    activity: activity,
                                    onBook: () => _showBookingSheet(
                                      activity,
                                      reservationState,
                                    ),
                                    icon: _categoryIcon(activity.category),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'WATER':
      case 'BEACH':
        return Icons.beach_access;
      case 'ADVENTURE':
        return Icons.directions_bike;
      case 'CULTURE':
        return Icons.museum;
      case 'FOOD':
      case 'DINING':
        return Icons.restaurant;
      case 'RELAXATION':
      case 'SPA':
        return Icons.spa;
      default:
        return Icons.tour;
    }
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.onBook,
    required this.icon,
  });

  final Activity activity;
  final VoidCallback onBook;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child:
                  activity.imagePath != null && activity.imagePath!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: activity.imagePath!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _ActivityFallback(icon: icon),
                      placeholder: (_, _) =>
                          Container(color: AppColors.lightGray),
                    )
                  : _ActivityFallback(icon: icon),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: AppTypography.sectionHeaderSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MUR ${activity.price.toStringAsFixed(0)}',
                      style: AppTypography.priceSmall.copyWith(
                        color: AppColors.oceanBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description?.trim().isNotEmpty == true
                      ? activity.description!
                      : 'Discover a carefully curated hotel experience during your stay.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: activity.category,
                    ),
                    _MetaChip(
                      icon: Icons.timer_outlined,
                      label: '${activity.duration} min',
                    ),
                    _MetaChip(
                      icon: Icons.people_outline,
                      label: 'Up to ${activity.capacity} guests',
                    ),
                    if (activity.meetingPoint?.trim().isNotEmpty == true)
                      _MetaChip(
                        icon: Icons.location_on_outlined,
                        label: activity.meetingPoint!,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.oceanBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Book this experience'),
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

class _ActivityFallback extends StatelessWidget {
  const _ActivityFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sandBeige, AppColors.lightGray],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 56,
          color: AppColors.oceanBlue.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.oceanBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionSmallBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionSmallBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
