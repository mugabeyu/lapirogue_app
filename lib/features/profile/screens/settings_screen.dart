import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(Icons.notifications_outlined, 'Notification Preferences', 'Manage push notifications'),
          _buildTile(Icons.language_outlined, 'Language', 'English'),
          _buildTile(Icons.storage_outlined, 'Clear Cache', 'Free up storage space'),
          _buildTile(Icons.download_outlined, 'Download Offline Content', 'Access without internet'),
          _buildTile(Icons.info_outline, 'App Version', '1.0.0'),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.oceanBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}