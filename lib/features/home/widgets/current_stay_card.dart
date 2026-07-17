import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/reservation.dart';

class CurrentStayCard extends StatelessWidget {
  final Reservation reservation;
  final String roomNumber;
  final String? roomImage;

  const CurrentStayCard({
    super.key,
    required this.reservation,
    required this.roomNumber,
    this.roomImage,
  });

  String get _statusLabel {
    switch (reservation.status) {
      case 'CHECKED_IN':
        return 'Checked In';
      case 'RESERVED':
      case 'CONFIRMED':
        return 'Reserved';
      case 'CHECKED_OUT':
      case 'COMPLETED':
        return 'Checked Out';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return reservation.status;
    }
  }

  Color get _statusColor {
    switch (reservation.status) {
      case 'CHECKED_IN':
        return AppColors.statusInfo;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      default:
        return AppColors.statusPending;
    }
  }

  Color get _statusBgColor {
    switch (reservation.status) {
      case 'CHECKED_IN':
        return AppColors.statusInfoBg;
      case 'CANCELLED':
        return AppColors.statusCancelledBg;
      default:
        return AppColors.statusPendingBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nights = reservation.checkOut.difference(reservation.checkIn).inDays;
    final checkInStr = DateFormat('MMM dd').format(reservation.checkIn);
    final checkOutStr = DateFormat('MMM dd').format(reservation.checkOut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your current stay', style: AppTypography.cardTitle),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/my-stay'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightGray2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: roomImage != null && roomImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: roomImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(color: AppColors.lightGray),
                              errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
                            )
                          : Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.55)],
                          ),
                        ),
                        child: Text(
                          roomNumber,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('$checkInStr \u2013 $checkOutStr \u00b7 $nights nights', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
