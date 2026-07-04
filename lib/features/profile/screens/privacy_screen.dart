import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Text(
                    'La Pirogue Hotel Mauritius is committed to protecting your privacy. '
                    'This policy outlines how we collect, use, and safeguard your personal information.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  Text('Information We Collect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(
                    'We collect information you provide directly, such as your name, email address, '
                    'phone number, and payment details when you make a reservation. We also collect '
                    'information automatically, including usage data and device information.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 16),
                  Text('How We Use Your Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text(
                    'Your information is used to process reservations, provide customer support, '
                    'send service updates, and improve our offerings. We do not sell your personal data to third parties.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOption('Share Usage Analytics', true),
        ],
      ),
    );
  }

  Widget _buildOption(String title, bool value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: value,
        onChanged: (_) {},
        secondary: const Icon(Icons.analytics_outlined, color: AppColors.darkNavy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}