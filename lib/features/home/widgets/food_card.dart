import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/menu_item.dart';
import '../../booking/screens/booking_screen.dart';

class FoodCard extends StatelessWidget {
  final MenuItem item;

  const FoodCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/booking', extra: BookingItem(
        type: BookingType.dining,
        id: item.id,
        name: item.name,
        imagePath: item.imagePath,
        price: item.price,
        category: item.category,
        description: item.description,
      )),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: item.imagePath != null && item.imagePath!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imagePath!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.lightGray),
                        errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
                      )
                    : Container(color: AppColors.lightGray, child: const Icon(Icons.restaurant, color: AppColors.textTertiary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(item.category, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Text('${item.preparationMinutes} min', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MUR ${item.price.toInt().toString()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
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
