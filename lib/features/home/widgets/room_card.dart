import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({super.key, required this.room});

  double get _rating {
    final hash = room.id.hashCode.abs();
    return 4.0 + (hash % 10) / 10.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/rooms/${room.id}'),
      child: Container(
        width: 280,
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
              child: Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: room.imagePath != null && room.imagePath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: room.imagePath!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: AppColors.lightGray),
                            errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
                          )
                        : Container(color: AppColors.lightGray, child: const Icon(Icons.image, color: AppColors.textTertiary)),
                  ),
                  if (room.type == 'VILLA' || room.type == 'SUITE')
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Popular', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
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
                      Expanded(
                        child: Text(room.roomNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.goldAccent),
                          const SizedBox(width: 2),
                          Text(_rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _iconText(Icons.people_outlined, '${room.capacity} guests'),
                      const SizedBox(width: 12),
                      _iconText(Icons.bed_outlined, room.type),
                      if (room.amenities.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        _iconText(Icons.visibility_outlined, room.amenities.first),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price per night', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('MUR ${room.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkNavy)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/rooms/${room.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
