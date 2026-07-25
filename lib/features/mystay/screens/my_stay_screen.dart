import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/reservation_status.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/models/guest_schedule_item.dart';

class MyStayScreen extends ConsumerStatefulWidget {
  const MyStayScreen({super.key});

  @override
  ConsumerState<MyStayScreen> createState() => _MyStayScreenState();
}

class _MyStayScreenState extends ConsumerState<MyStayScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.villa_outlined,
            title: 'My Stay',
            message: 'Sign in to see your room, schedule and bill.',
            actionLabel: 'Sign in',
            onAction: () => context.push('/login'),
          ),
        ),
      );
    }

    if (!reservationState.hasActiveReservation) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.villa_outlined,
            title: 'No active stay',
            message: 'When you book a room it will appear here with everything you need.',
            actionLabel: 'Browse rooms',
            onAction: () => context.push('/rooms'),
          ),
        ),
      );
    }

    final reservation = reservationState.activeReservation!;
    final room = reservation.room;
    final statusInfo = ReservationStatusInfo.forStatus(reservation.status);
    final nights = reservation.checkOut.difference(reservation.checkIn).inDays;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(reservationProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              AppTheme.space4,
              AppTheme.screenPadding,
              AppTheme.space10,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(child: Text('My stay', style: AppTypography.display)),
                  StatusPill(label: statusInfo.label, tone: statusInfo.tone),
                ],
              ),
              const SizedBox(height: AppTheme.space6),

              if (room != null) ...[
                _RoomCard(
                  imagePath: room.imagePath,
                  roomNumber: room.roomNumber,
                  type: room.type,
                  capacity: room.capacity,
                ),
                const SizedBox(height: AppTheme.space5),
              ],

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stay details', style: AppTypography.cardTitle),
                    const SizedBox(height: AppTheme.space3),
                    DetailRow(
                      icon: Icons.login_rounded,
                      label: 'Check-in',
                      value: formatDate(reservation.checkIn),
                    ),
                    const Divider(),
                    DetailRow(
                      icon: Icons.logout_rounded,
                      label: 'Check-out',
                      value: formatDate(reservation.checkOut),
                    ),
                    const Divider(),
                    DetailRow(
                      icon: Icons.nightlight_outlined,
                      label: 'Duration',
                      value: formatNights(nights),
                    ),
                    const Divider(),
                    DetailRow(
                      icon: Icons.group_outlined,
                      label: 'Guests',
                      value: formatOccupancy(
                        reservation.adults,
                        reservation.children,
                      ),
                    ),
                    const Divider(),
                    DetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Room total',
                      value: formatMoney(reservation.totalAmount),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space8),
              SectionHeading(
                title: 'Today',
                actionLabel: 'View all',
                onAction: () => context.push('/daily-schedule'),
              ),
              const _DailyScheduleSection(),

              const SizedBox(height: AppTheme.space8),
              SectionHeading(
                title: 'Your bill',
                actionLabel: 'View all',
                onAction: () => context.push('/payments'),
              ),
              const _BillingSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String? imagePath;
  final String roomNumber;
  final String type;
  final int capacity;

  const _RoomCard({
    required this.imagePath,
    required this.roomNumber,
    required this.type,
    required this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: imagePath != null && imagePath!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imagePath!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: AppColors.surfaceMuted),
                      errorWidget: (_, _, _) => const _RoomImageFallback(),
                    )
                  : const _RoomImageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR ROOM', style: AppTypography.overline),
                  const SizedBox(height: AppTheme.space2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(roomNumber, style: AppTypography.heading),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Text(
                          type,
                          style: AppTypography.body,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: AppTheme.space1),
                      Text('Sleeps $capacity', style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomImageFallback extends StatelessWidget {
  const _RoomImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Icon(Icons.villa_outlined,
          size: 40, color: AppColors.textTertiary),
    );
  }
}

class _DailyScheduleSection extends StatefulWidget {
  const _DailyScheduleSection();

  @override
  State<_DailyScheduleSection> createState() => _DailyScheduleSectionState();
}

class _DailyScheduleSectionState extends State<_DailyScheduleSection> {
  List<GuestScheduleItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final guest = await GuestService().getCurrentGuest();
    if (guest == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      await ScheduleService().autoCompleteOverdueItems(guest.id);
      final items = await ScheduleService().getScheduleForGuest(guest.id);
      final today = DateTime.now();
      if (!mounted) return;
      setState(() {
        _items = items
            .where((item) =>
                item.startAt.year == today.year &&
                item.startAt.month == today.month &&
                item.startAt.day == today.day)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const InlineLoader();

    if (_items.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined,
                size: 20, color: AppColors.textTertiary),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Text('Nothing scheduled today.', style: AppTypography.body),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space5,
        vertical: AppTheme.space4,
      ),
      child: Column(
        children: [
          for (var i = 0; i < _items.take(4).length; i++) ...[
            if (i > 0) const Divider(height: AppTheme.space5),
            _ScheduleRow(item: _items[i]),
          ],
          if (_items.length > 4) ...[
            const SizedBox(height: AppTheme.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('+${_items.length - 4} more today',
                  style: AppTypography.caption),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final GuestScheduleItem item;
  const _ScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDone = item.status.toUpperCase() == 'COMPLETED';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space2,
            vertical: AppTheme.space1,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            formatTime(item.startAt),
            style: AppTypography.small.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: Text(
            item.title,
            style: AppTypography.bodyMedium.copyWith(
              color: isDone ? AppColors.textTertiary : AppColors.textPrimary,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isDone)
          const Icon(Icons.check_circle,
              size: 18, color: AppColors.success),
      ],
    );
  }
}

class _BillingSection extends StatefulWidget {
  const _BillingSection();

  @override
  State<_BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends State<_BillingSection> {
  BillingSummary? _billing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final billing = await BillingService().getBillingSummary(guestId);
      if (!mounted) return;
      setState(() {
        _billing = billing;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  StatusTone _toneFor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
        return StatusTone.success;
      case 'PARTIALLY_PAID':
        return StatusTone.warning;
      default:
        return StatusTone.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const InlineLoader();

    final billing = _billing;
    if (billing == null) {
      return AppCard(
        child: Text('No charges on your account yet.', style: AppTypography.body),
      );
    }

    final settled = billing.balanceDue <= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: humanizeStatus(billing.status),
                tone: _toneFor(billing.status),
              ),
              const Spacer(),
              Text(
                settled
                    ? 'Nothing due'
                    : '${formatMoney(billing.balanceDue)} due',
                style: AppTypography.priceSmall.copyWith(
                  color: settled ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Row(
            children: [
              StatTile(
                label: 'Charges',
                value: formatMoney(billing.totalCharges),
              ),
              const SizedBox(width: AppTheme.space2),
              StatTile(
                label: 'Paid',
                value: formatMoney(billing.totalPaid),
                valueColor: AppColors.success,
              ),
              const SizedBox(width: AppTheme.space2),
              StatTile(
                label: 'Balance',
                value: formatMoney(billing.balanceDue),
                valueColor: settled ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
