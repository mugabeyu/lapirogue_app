import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../booking/screens/booking_screen.dart';

class SpecialRequestBanner extends StatelessWidget {
  const SpecialRequestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDF8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need something special?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Request housekeeping, airport transfer, extra amenities, or concierge assistance.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.push('/booking', extra: BookingItem(
                    type: BookingType.customRequest,
                    id: '',
                    name: 'Custom Request',
                    price: 0,
                    description: 'Make a custom request to the hotel staff',
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Make Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.mail_outline, size: 48, color: AppColors.darkNavy.withValues(alpha: 0.15)),
        ],
      ),
    );
  }
}
