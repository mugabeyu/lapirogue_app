import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class FloatingSupportButton extends StatelessWidget {
  final double? bottom;
  final double? right;

  const FloatingSupportButton({super.key, this.bottom, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom ?? 24,
      right: right ?? 20,
      child: GestureDetector(
        onTap: () => context.push('/messages'),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.darkNavy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.darkNavy.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.support_agent, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
