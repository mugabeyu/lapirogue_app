import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../core/models/guest_schedule_item.dart';
import '../../../core/models/reservation.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CHECKED_IN':
        return AppColors.statusConfirmed;
      case 'RESERVED':
        return AppColors.darkNavy;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _shortRef(String value) {
    if (value.isEmpty) return 'Pending';
    return value.length <= 8 ? value : value.substring(0, 8);
  }

  Future<List<Reservation>> _fetchGuestReservations(String guestId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('reservations')
          .select('*, rooms(*)')
          .eq('guest_id', guestId)
          .order('check_in', ascending: false);

      return (response as List)
          .map((r) => Reservation.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reservations: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Reservations'),
          backgroundColor: AppColors.darkNavy,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hotel, size: 60, color: AppColors.darkNavy),
                const SizedBox(height: 24),
                const Text(
                  'Sign in to view your reservations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        backgroundColor: AppColors.darkNavy,
      ),
      body: FutureBuilder<String?>(
        future: SessionService.getCurrentGuestId(),
        builder: (context, guestIdSnapshot) {
          if (guestIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!guestIdSnapshot.hasData || guestIdSnapshot.data == null) {
            return const Center(child: Text('Unable to load guest info'));
          }

          final guestId = guestIdSnapshot.data!;
          return FutureBuilder<List<Reservation>>(
            future: _fetchGuestReservations(guestId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final reservations = snapshot.data ?? [];

              if (reservations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 60,
                          color: AppColors.darkNavy,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Reservations Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Start exploring rooms and make your first reservation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.push('/rooms'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkNavy,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Browse Rooms'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getStatusColor(reservation.status),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reservation.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Ref: ${_shortRef(reservation.reservationId)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.darkNavy,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Check-in',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(reservation.checkIn),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Check-out',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(reservation.checkOut),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 18,
                                    color: AppColors.darkNavy,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${reservation.adults} Adult${reservation.adults != 1 ? 's' : ''} ${reservation.children > 0 ? '• ${reservation.children} Child${reservation.children != 1 ? 'ren' : ''}' : ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.meeting_room_outlined,
                                    size: 18,
                                    color: AppColors.darkNavy,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      reservation.room != null
                                          ? 'Room ${reservation.room!.roomNumber} - ${reservation.room!.type}'
                                          : 'Room assignment pending',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'MUR ${reservation.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/payments'),
                                  icon: const Icon(Icons.receipt),
                                  label: const Text('View Payment'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _DailyScheduleSection(
                                reservation: reservation,
                                key: ValueKey(reservation.id),
                              ),
                              if (reservation.isConfirmed) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        context.push('/activities'),
                                    icon: const Icon(Icons.tour_outlined),
                                    label: const Text(
                                      'Book Activities & Tours',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DailyScheduleSection extends StatefulWidget {
  final Reservation reservation;

  const _DailyScheduleSection({super.key, required this.reservation});

  @override
  State<_DailyScheduleSection> createState() => _DailyScheduleSectionState();
}

class _DailyScheduleSectionState extends State<_DailyScheduleSection> {
  late Future<List<GuestScheduleItem>> _future;
  final _ecoService = EcoPointsService();
  int _ecoPointsBalance = 0;
  bool _ecoLoaded = false;

  @override
  void initState() {
    super.initState();
    _future = _loadItems();
    _loadEcoBalance();
  }

  Future<void> _loadEcoBalance() async {
    final guestId = widget.reservation.guestId;
    if (guestId == null) return;
    final balance = await _ecoService.getEcoPointsBalance(guestId);
    if (!mounted) return;
    setState(() {
      _ecoPointsBalance = balance;
      _ecoLoaded = true;
    });
  }

  Future<List<GuestScheduleItem>> _loadItems() async {
    final guestId = widget.reservation.guestId;
    if (guestId == null) return [];

    final stayStart = DateTime(
      widget.reservation.checkIn.year,
      widget.reservation.checkIn.month,
      widget.reservation.checkIn.day,
    );
    final stayEnd = DateTime(
      widget.reservation.checkOut.year,
      widget.reservation.checkOut.month,
      widget.reservation.checkOut.day,
      23,
      59,
    );

    final items = await ScheduleService().getScheduleForGuest(
      guestId,
      fromDate: stayStart,
      toDate: stayEnd,
    );

    final filtered = items
        .where(
          (item) =>
              item.sourceModule != 'reservations' ||
              item.id.contains(widget.reservation.id),
        )
        .toList();

    filtered.sort((a, b) {
      final aDone = a.status.toUpperCase() == 'COMPLETED';
      final bDone = b.status.toUpperCase() == 'COMPLETED';
      if (aDone != bDone) return aDone ? 1 : -1;
      return a.startAt.compareTo(b.startAt);
    });

    return filtered;
  }

  Future<void> _completeItem(GuestScheduleItem item) async {
    final guestId = widget.reservation.guestId;
    if (guestId == null) return;

    final success = await ScheduleService().markItemCompleted(
      item.id,
      sourceModule: item.sourceModule,
    );

    if (!mounted) return;

    final alreadyCompleted = item.status.toUpperCase() == 'COMPLETED';

    if (!success && !alreadyCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete this schedule item.')),
      );
      return;
    }

    await EcoPointsService().earnPoints(
      guestId: guestId,
      points: 25,
      description: 'Completed scheduled activity: ${item.title}',
      sourceType: 'SCHEDULE',
      sourceRecordId: item.id,
    );

    if (!mounted) return;
    _future = _loadItems();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('+25 eco-points earned. Schedule item completed.'),
        backgroundColor: AppColors.statusConfirmed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canComplete = widget.reservation.isCheckedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28),
        Row(
          children: [
            const Icon(Icons.event_note, color: AppColors.darkNavy, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Daily Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/daily-schedule'),
              child: const Text('View All'),
            ),
          ],
        ),
        if (_ecoLoaded) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco, size: 18, color: AppColors.statusConfirmed),
                const SizedBox(width: 6),
                Text(
                  '$_ecoPointsBalance eco-points earned',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusConfirmed,
                  ),
                ),
              ],
            ),
          ),
        ],
        FutureBuilder<List<GuestScheduleItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.reservation.isConfirmed
                      ? 'No activities planned yet. Book tours for your stay dates to build your itinerary.'
                      : 'Your daily schedule will appear here once your reservation is confirmed.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              );
            }

            final displayItems = items.length > 4 ? items.sublist(0, 4) : items;
            return Column(
              children: displayItems.map((item) {
                final completed = item.status.toUpperCase() == 'COMPLETED';
                final finished = DateTime.now().isAfter(item.endAt);
                final completable =
                    canComplete &&
                    finished &&
                    !completed &&
                    item.sourceModule != 'reservations';

                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.statusConfirmed.withValues(alpha: 0.08)
                        : AppColors.lightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d, HH:mm').format(item.startAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: completed
                                  ? AppColors.statusConfirmed
                                  : AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.location?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (completable) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _completeItem(item),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text(
                              'Mark Completed (+25 eco-points)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusConfirmed,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
