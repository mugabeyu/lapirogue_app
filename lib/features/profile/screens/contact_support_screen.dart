import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
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
                  Row(
                    children: [
                      Icon(Icons.headset_mic, color: AppColors.darkNavy, size: 28),
                      SizedBox(width: 12),
                      Text('We\'re here to help', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Our support team is available 24/7 to assist you with any questions or concerns.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildContactTile(Icons.phone, 'Call Us', '+230 1234 5678', 'Available 24/7'),
          const SizedBox(height: 12),
          _buildContactTile(Icons.email_outlined, 'Email Us', 'support@lapirogue.com', 'We reply within 2 hours'),
          const SizedBox(height: 12),
          _buildContactTile(Icons.chat_outlined, 'Live Chat', 'Start a conversation', 'Available 8AM - 10PM'),
          const SizedBox(height: 12),
          _buildContactTile(Icons.location_on_outlined, 'Visit Us', 'La Pirogue, Belle Mare, Mauritius', 'Front Desk: 24/7'),
        ],
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String detail, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.darkNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.darkNavy),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}