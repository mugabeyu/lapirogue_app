import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final nights = reservation.checkOut.difference(reservation.checkIn).inDays;
    final checkInStr = DateFormat('MMM dd').format(reservation.checkIn);
    final checkOutStr = DateFormat('MMM dd').format(reservation.checkOut);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 140,
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
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(roomNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusConfirmed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Checked In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.statusConfirmed)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('$checkInStr \u2013 $checkOutStr \u00b7 $nights nights', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.people_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${reservation.adults + reservation.children} guests', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                _actionButton(context, Icons.date_range_outlined, 'Extend Stay', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.lightGray2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.darkNavy),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
