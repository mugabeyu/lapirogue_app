import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/models/reservation.dart';
import '../../../core/utils/reservation_status.dart';

/// Read-only reservation detail view. Guests can view everything about a
/// booking here, but there is no cancel/status control on this screen —
/// only hotel staff transition a reservation's status once it's been made.
class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  Reservation? _reservation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await Supabase.instance.client
          .from('reservations')
          .select('*, rooms(*)')
          .eq('id', widget.reservationId)
          .single();
      if (!mounted) return;
      setState(() {
        _reservation = Reservation.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'We couldn\'t load this reservation. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reservation'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : _buildContent(_reservation!),
    );
  }

  Widget _buildContent(Reservation reservation) {
    final room = reservation.room;
    final nights = reservation.checkOut.difference(reservation.checkIn).inDays;
    final statusInfo = ReservationStatusInfo.forStatus(reservation.status);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: room?.imagePath != null && room!.imagePath!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: room.imagePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.lightGray),
                        errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.villa, color: AppColors.textTertiary)),
                      )
                    : Container(color: AppColors.lightGray, child: const Icon(Icons.villa, color: AppColors.textTertiary)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.6)],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (room != null)
                              Text('Room ${room.roomNumber}', style: AppTypography.caption.copyWith(color: Colors.white)),
                            Text(
                              room?.type ?? 'Reservation',
                              style: AppTypography.sectionTitle.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: statusInfo.backgroundColor, borderRadius: BorderRadius.circular(999)),
                        child: Text(statusInfo.label, style: AppTypography.small.copyWith(fontWeight: FontWeight.w700, color: statusInfo.color)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LP-${reservation.reservationId.isNotEmpty ? reservation.reservationId : reservation.id.substring(0, 8)}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoBox(Icons.calendar_month_outlined, 'Check-in', DateFormat('yyyy-MM-dd').format(reservation.checkIn))),
                    const SizedBox(width: 12),
                    Expanded(child: _infoBox(Icons.calendar_month_outlined, 'Check-out', DateFormat('yyyy-MM-dd').format(reservation.checkOut))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _infoBox(Icons.nightlight_outlined, 'Nights', '$nights')),
                    const SizedBox(width: 12),
                    Expanded(child: _infoBox(Icons.group_outlined, 'Guests', '${reservation.adults + reservation.children}')),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.tag, 'Booking reference', reservation.reservationId.isNotEmpty ? reservation.reservationId : reservation.id),
                if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text(reservation.notes!, style: AppTypography.caption.copyWith(color: AppColors.textPrimary))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Price breakdown', style: AppTypography.cardTitle),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _priceRow('Room ($nights night${nights == 1 ? '' : 's'})', reservation.totalAmount),
                      const Divider(height: 24),
                      _priceRow('Total', reservation.totalAmount, isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGray2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cancellation policy', style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        'Free cancellation up to 48 hours before check-in. After that, the first night is non-refundable. To cancel or change this reservation, please contact the front desk.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: AppTypography.captionMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          // The total steps up a level in the scale so it reads as the sum of
          // the lines above it rather than another line item.
          style: isTotal ? AppTypography.bodyMedium : AppTypography.body,
        ),
        Text(
          formatMoney(amount),
          style: isTotal
              ? AppTypography.priceSmall.copyWith(color: AppColors.primary)
              : AppTypography.captionMedium,
        ),
      ],
    );
  }
}
