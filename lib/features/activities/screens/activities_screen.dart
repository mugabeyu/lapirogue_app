import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reservation_gate.dart';
import '../../../core/models/activity.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../booking/screens/booking_screen.dart';

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

  Future<void> _bookActivity(Activity activity) async {
    final reservationState = ref.read(reservationProvider);
    if (!reservationState.hasActiveReservation) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please make a reservation first')),
        );
      }
      return;
    }

    if (!mounted) return;
    context.push(
      '/booking',
      extra: BookingItem(
        type: BookingType.activity,
        id: activity.id,
        name: activity.name,
        imagePath: activity.imagePath,
        price: activity.price,
        category: activity.category,
        description: activity.description,
        duration: activity.duration,
        capacity: activity.capacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          foregroundColor: AppColors.darkNavy,
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
                                AppColors.darkNavy,
                                AppColors.darkNavyLight,
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
                                style: AppTypography.sectionTitle.copyWith(
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
                                    : AppColors.darkNavy,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.darkNavy,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.darkNavy
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
                                style: AppTypography.cardTitle
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
                                    onBook: () => _bookActivity(activity),
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
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MUR ${activity.price.toStringAsFixed(0)}',
                      style: AppTypography.priceSmall.copyWith(
                        color: AppColors.darkNavy,
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
                      backgroundColor: AppColors.darkNavy,
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
          colors: [AppColors.goldAccentLight, AppColors.lightGray],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 56,
          color: AppColors.darkNavy.withValues(alpha: 0.55),
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
          Icon(icon, size: 15, color: AppColors.darkNavy),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
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
            style: AppTypography.captionMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
