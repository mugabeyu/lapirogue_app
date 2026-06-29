import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../../core/models/guest.dart';
import '../../feedback/screens/feedback_screen.dart';

/// Settings Screen - Combined guest profile and account settings
/// Shows current stay, full names, reservation date, change password, upload guest photo
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Guest? _guest;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadGuestData();
  }

  Future<void> _loadGuestData() async {
    final guest = await GuestService().getCurrentGuest();
    if (mounted) {
      setState(() {
        _guest = guest;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_guest == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }
      final bytes = await pickedFile.readAsBytes();
      final imageUrl = await StorageService().uploadGuestPhoto(_guest!.id, bytes);
      if (imageUrl != null) {
        await GuestService().updateProfileImagePath(_guest!.id, imageUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully'), backgroundColor: AppTheme.accentGreen),
          );
          _loadGuestData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload photo'), backgroundColor: AppTheme.accentRed),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_guest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('Please log in to continue', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final reservation = _guest!.reservations?.isNotEmpty == true ? _guest!.reservations![0] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card - shows full name and photo
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _guest!.imagePath != null ? NetworkImage(_guest!.imagePath!) : null,
                          child: _guest!.imagePath == null ? const Icon(Icons.person, size: 40) : null,
                        ),
                        if (_isUploadingPhoto)
                          const Positioned.fill(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _guest!.fullName.isNotEmpty ? _guest!.fullName : 'Guest',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_guest!.email, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current Stay Section - shows room, reservation dates
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Stay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (reservation != null) ...[
                    _buildInfoRow('Reservation #', reservation.reservationId),
                    _buildInfoRow('Room', reservation.room?.roomNumber ?? '--'),
                    _buildInfoRow('Check-in Date', reservation.checkIn.toIso8601String().split('T').first),
                    _buildInfoRow('Check-out Date', reservation.checkOut.toIso8601String().split('T').first),
                    _buildInfoRow('Status', reservation.status),
                  ] else ...[
                    const Icon(Icons.hotel, size: 48, color: AppTheme.textTertiary),
                    const SizedBox(height: 12),
                    const Text(
                      'No active reservation found',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please contact reception for assistance',
                      style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // My Stay - Feedback
          const Text(
            'My Stay',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.feedback_outlined, color: AppTheme.accentGreen),
                  title: const Text('Feedback'),
                  subtitle: const Text('Share your experience'),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Account
          const Text(
            'Account',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock, color: AppTheme.primary),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}