import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/reservation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String reservationId;
  final String checkIn;
  final String checkOut;

  const BookingConfirmationScreen({
    super.key,
    required this.reservationId,
    required this.checkIn,
    required this.checkOut,
  });

  String _formatDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<Reservation?> _fetchReservation() async {
    if (reservationId.isEmpty) return null;

    final response = await Supabase.instance.client
        .from('reservations')
        .select('*, rooms(*)')
        .eq('reservation_id', reservationId)
        .maybeSingle();

    return response == null ? null : Reservation.fromJson(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Reservation?>(
        future: _fetchReservation(),
        builder: (context, snapshot) {
          final reservation = snapshot.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.statusConfirmed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.statusConfirmed,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reservation Confirmed!',
                  style: AppTypography.heading.copyWith(color: AppColors.darkNavy),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your room has been successfully booked.',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.statusConfirmed.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reservation?.status ?? 'RESERVED',
                              style: AppTypography.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.statusConfirmed),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '#${reservation?.reservationId ?? (reservationId.length > 8 ? reservationId.substring(0, 8) : reservationId)}',
                            style: AppTypography.small.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _detailRow(
                        Icons.info_outline,
                        'Status',
                        (reservation?.status ?? 'RESERVED').replaceAll(
                          '_',
                          ' ',
                        ),
                      ),
                      const Divider(height: 24),
                      _detailRow(
                        Icons.calendar_today,
                        'Check-in',
                        reservation != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(reservation.checkIn)
                            : _formatDate(checkIn),
                      ),
                      const Divider(height: 24),
                      _detailRow(
                        Icons.calendar_today,
                        'Check-out',
                        reservation != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(reservation.checkOut)
                            : _formatDate(checkOut),
                      ),
                      if (reservation != null) ...[
                        const Divider(height: 24),
                        _detailRow(
                          Icons.meeting_room_outlined,
                          'Room',
                          reservation.room != null
                              ? '${reservation.room!.roomNumber} - ${reservation.room!.type}'
                              : 'Room assignment pending',
                        ),
                        const Divider(height: 24),
                        _detailRow(
                          Icons.people_outline,
                          'Guests',
                          '${reservation.adults} adult${reservation.adults == 1 ? '' : 's'}${reservation.children > 0 ? ', ${reservation.children} child${reservation.children == 1 ? '' : 'ren'}' : ''}',
                        ),
                        const Divider(height: 24),
                        _detailRow(
                          Icons.payments_outlined,
                          'Total',
                          'MUR ${reservation.totalAmount.toStringAsFixed(2)}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/reservations'),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('View My Reservations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/activities'),
                    icon: const Icon(Icons.explore),
                    label: const Text('Browse Activities & Tours'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkNavy,
                      side: const BorderSide(color: AppColors.darkNavy),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.goldAccent),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
