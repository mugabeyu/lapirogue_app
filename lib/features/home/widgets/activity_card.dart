import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/activity.dart';
import '../../booking/screens/booking_screen.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;

  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/booking', extra: BookingItem(
        type: BookingType.activity,
        id: activity.id,
        name: activity.name,
        imagePath: activity.imagePath,
        price: activity.price,
        category: activity.category,
        description: activity.description,
        duration: activity.duration,
        capacity: activity.capacity,
      )),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
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
                child: activity.imagePath != null && activity.imagePath!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: activity.imagePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.lightGray),
                        errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
                      )
                    : Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: AppColors.goldAccent),
                      const SizedBox(width: 2),
                      Text('4.8', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Icon(Icons.timer_outlined, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Text('${activity.duration} min', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text('MUR ${activity.price.toInt().toString()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/booking', extra: BookingItem(
                        type: BookingType.activity,
                        id: activity.id,
                        name: activity.name,
                        imagePath: activity.imagePath,
                        price: activity.price,
                        category: activity.category,
                        description: activity.description,
                        duration: activity.duration,
                        capacity: activity.capacity,
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Book Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
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
