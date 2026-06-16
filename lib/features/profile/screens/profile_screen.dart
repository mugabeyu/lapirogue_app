import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/guest.dart';
import '../../../core/models/reservation.dart';
import '../../../core/theme/app_theme.dart';
import '../../payments/screens/payments_screen.dart';
import '../../feedback/screens/feedback_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    if (mounted) setState(() { _guest = guest; _isLoading = false; });
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_guest == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile == null) { setState(() => _isUploadingPhoto = false); return; }
      final file = File(pickedFile.path);
      final imageUrl = await StorageService().uploadGuestPhoto(_guest!.id, file);
      if (imageUrl != null) {
        await GuestService().updateProfileImagePath(_guest!.id, imageUrl);
        await _loadGuestData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated'), backgroundColor: AppTheme.accentGreen),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo'), backgroundColor: AppTheme.accentRed),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Photo upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await SupabaseService.signOut();
      } catch (_) {}
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final guest = _guest;
    final reservation = guest?.reservations?.isNotEmpty == true ? guest!.reservations![0] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isUploadingPhoto)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(guest),
            const SizedBox(height: 20),
            if (reservation != null) _buildCurrentStayCard(reservation),
            const SizedBox(height: 12),
            _buildMenuGrid(),
            const SizedBox(height: 24),
            _buildSignOutButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Guest? guest) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primaryLight.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAndUploadPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white24,
                      backgroundImage: guest?.imagePath != null ? NetworkImage(guest!.imagePath!) : null,
                      child: guest?.imagePath == null
                          ? const Icon(Icons.person_rounded, size: 48, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: AppTheme.primary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                guest?.fullName.isNotEmpty == true ? guest!.fullName : 'Guest',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (guest?.email.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(guest!.email, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                ),
              if (guest != null && guest.guestId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('ID: ${guest.guestId}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStayCard(Reservation reservation) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateTo(const PaymentsScreen()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room ${reservation.room?.roomNumber ?? '--'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${reservation.checkIn.toIso8601String().split('T').first} → ${reservation.checkOut.toIso8601String().split('T').first}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reservation.status,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return Column(
      children: [
        _buildMenuRow([
          _ProfileMenuItem(Icons.receipt_long, 'Payments', AppTheme.accentGreen, () => _navigateTo(const PaymentsScreen())),
          _ProfileMenuItem(Icons.feedback_outlined, 'Feedback', AppTheme.secondary, () => _navigateTo(const FeedbackScreen())),
        ]),
        const SizedBox(height: 12),
        _buildMenuRow([
          _ProfileMenuItem(Icons.lock_outline, 'Change Password', AppTheme.primaryLight, () => _navigateTo(const ChangePasswordScreen())),
          _ProfileMenuItem(Icons.settings_outlined, 'Settings', AppTheme.textSecondary, () => _navigateTo(const SettingsScreen())),
        ]),
      ],
    );
  }

  Widget _buildMenuRow(List<_ProfileMenuItem> items) {
    return Row(
      children: items.map((item) => Expanded(child: _buildMenuItemCard(item))).toList(),
    );
  }

  Widget _buildMenuItemCard(_ProfileMenuItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accentRed,
          side: const BorderSide(color: AppTheme.accentRed),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ProfileMenuItem(this.icon, this.label, this.color, this.onTap);
}
