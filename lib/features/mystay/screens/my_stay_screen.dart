import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/models/guest_schedule_item.dart';

class MyStayScreen extends ConsumerWidget {
  const MyStayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                    child: const Icon(Icons.villa_outlined, size: 48, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  const Text('My Stay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Sign in to view your stay details', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!reservationState.hasActiveReservation) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                    child: const Icon(Icons.villa_outlined, size: 48, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  const Text('No Active Stay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('You don\'t have an active reservation', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/rooms'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Book a Room'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final reservation = reservationState.activeReservation!;
    final room = reservation.room;
    final isCheckedIn = reservation.status == 'CHECKED_IN';
    final isReserved = reservation.status == 'RESERVED' || reservation.status == 'CONFIRMED';
    final nights = reservation.checkOut.difference(reservation.checkIn).inDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('My Stay', style: AppTypography.heading)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCheckedIn
                          ? const Color(0xFF2F855A).withValues(alpha: 0.12)
                          : isReserved
                              ? AppColors.goldAccent.withValues(alpha: 0.12)
                              : AppColors.textTertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reservation.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isCheckedIn
                            ? const Color(0xFF2F855A)
                            : isReserved
                                ? AppColors.goldAccent
                                : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (room != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: room.imagePath != null && room.imagePath!.isNotEmpty
                              ? CachedNetworkImage(imageUrl: room.imagePath!, fit: BoxFit.cover, placeholder: (_, _) => Container(color: AppColors.lightGray), errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)))
                              : Container(color: AppColors.lightGray, child: const Icon(Icons.villa, color: AppColors.textTertiary)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(room.roomNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Text(room.type, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _infoChip(Icons.people_outlined, '${room.capacity} guests'),
                                const SizedBox(width: 8),
                                _infoChip(Icons.bed_outlined, room.type),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stay Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    _detailRow(Icons.calendar_today, 'Check-in', DateFormat('MMM dd, yyyy').format(reservation.checkIn)),
                    const SizedBox(height: 12),
                    _detailRow(Icons.calendar_today, 'Check-out', DateFormat('MMM dd, yyyy').format(reservation.checkOut)),
                    const SizedBox(height: 12),
                    _detailRow(Icons.nightlight_outlined, 'Nights', '$nights night${nights > 1 ? 's' : ''}'),
                    const SizedBox(height: 12),
                    _detailRow(Icons.group_outlined, 'Guests', '${reservation.adults} adult${reservation.adults > 1 ? 's' : ''}${reservation.children > 0 ? ', ${reservation.children} children' : ''}'),
                    const SizedBox(height: 12),
                    _detailRow(Icons.payments_outlined, 'Total', 'MUR ${reservation.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Daily Schedule', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              _DailyScheduleSection(),
              const SizedBox(height: 24),
              const Text('Payments', style: AppTypography.sectionTitle),
              const SizedBox(height: 12),
              _PaymentsSection(),
              if (isReserved) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Reservation'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusCancelled,
                      side: const BorderSide(color: AppColors.statusCancelled),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

}

class _DailyScheduleSection extends StatefulWidget {
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
    if (guest == null) { setState(() => _isLoading = false); return; }
    try {
      await ScheduleService().autoCompleteOverdueItems(guest.id);
      final items = await ScheduleService().getScheduleForGuest(guest.id);
      final today = DateTime.now();
      setState(() {
        _items = items.where((item) =>
          item.startAt.year == today.year &&
          item.startAt.month == today.month &&
          item.startAt.day == today.day
        ).toList();
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, size: 18, color: AppColors.darkNavy),
              const SizedBox(width: 8),
              Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/daily-schedule'),
                child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.goldAccent, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.event_available, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text('No activities scheduled today', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ..._items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.darkNavy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text(DateFormat('HH:mm').format(item.startAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.title, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (item.status.toUpperCase() == 'COMPLETED')
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF2F855A)),
                ],
              ),
            )),
          if (_items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${_items.length - 3} more', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
        ],
      ),
    );
  }
}

class _PaymentsSection extends StatefulWidget {
  @override
  State<_PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends State<_PaymentsSection> {
  BillingSummary? _billing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) { setState(() => _isLoading = false); return; }
    try {
      _billing = await BillingService().getBillingSummary(guestId);
      setState(() => _isLoading = false);
    } catch (_) { setState(() => _isLoading = false); }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID': case 'COMPLETED': return AppColors.statusConfirmed;
      case 'PARTIALLY_PAID': return AppColors.goldAccent;
      default: return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));

    final b = _billing;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_outlined, size: 18, color: AppColors.darkNavy),
              const SizedBox(width: 8),
              const Text('Billing Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/payments'),
                child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.goldAccent, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (b == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No billing info available', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            )
          else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(b.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(b.status.replaceAll('_', ' '), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(b.status))),
                ),
                const Spacer(),
                Text('MUR ${b.balanceDue.toStringAsFixed(0)} due', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _statusColor(b.status))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _billCard('Total Charges', 'MUR ${b.totalCharges.toStringAsFixed(0)}', AppColors.darkNavy),
                const SizedBox(width: 8),
                _billCard('Total Paid', 'MUR ${b.totalPaid.toStringAsFixed(0)}', AppColors.statusConfirmed),
                const SizedBox(width: 8),
                _billCard('Balance', 'MUR ${b.balanceDue.toStringAsFixed(0)}', b.balanceDue > 0 ? AppColors.goldAccent : AppColors.statusConfirmed),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _billCard(String label, String amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
