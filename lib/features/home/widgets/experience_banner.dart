import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Single full-width "explore activities" banner shown on the home screen,
/// replacing a horizontal list of individual activity cards — matching the
/// reference design's "EXPERIENCES" photo banner rather than a card row.
class ExperienceBanner extends StatelessWidget {
  final String? imageUrl;

  const ExperienceBanner({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push('/activities'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.lightGray),
                        errorWidget: (_, _, _) => Container(color: AppColors.darkNavy),
                      )
                    : Container(color: AppColors.darkNavy),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.65)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPERIENCES',
                      style: AppTypography.small.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sail into a La Pirogue sunset',
                      style: AppTypography.sectionTitle.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Explore activities', style: AppTypography.captionMedium.copyWith(color: Colors.white.withValues(alpha: 0.95))),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
