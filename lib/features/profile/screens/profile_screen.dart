import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/reservation_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showPhotoOptions(BuildContext context, WidgetRef ref, String guestId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Profile Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.darkNavy),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUpload(context, ref, guestId, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.darkNavy),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUpload(context, ref, guestId, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.statusCancelled),
                title: const Text('Remove Photo', style: TextStyle(color: AppColors.statusCancelled)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _removePhoto(context, ref, guestId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref, String guestId, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final url = await StorageService().uploadGuestPhoto(guestId, bytes);
      if (url == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload photo'), behavior: SnackBarBehavior.floating));
        return;
      }

      await Supabase.instance.client.from('guests').update({'image_path': url}).eq('id', guestId);
      ref.read(authStateProvider.notifier).refreshGuest();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _removePhoto(BuildContext context, WidgetRef ref, String guestId) async {
    try {
      await Supabase.instance.client.from('guests').update({'image_path': null}).eq('id', guestId);
      ref.read(authStateProvider.notifier).refreshGuest();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed'), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/lapirogue_logo.jpg', height: 90, fit: BoxFit.contain),
                ),
                const SizedBox(height: 24),
                const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Sign in to manage your profile and preferences', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Login'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final guest = authState.guest!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.darkNavy,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkNavy, AppColors.darkNavyDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 100),
                    GestureDetector(
                      onTap: () => _showPhotoOptions(context, ref, guest.id),
                      child: Stack(
                        children: [
                          Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              image: guest.imagePath != null
                                  ? DecorationImage(image: NetworkImage(guest.imagePath!), fit: BoxFit.cover)
                                  : null,
                              color: AppColors.goldAccent,
                            ),
                            child: guest.imagePath == null
                                ? Center(child: Text('${guest.firstName[0]}${guest.lastName[0]}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)))
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.darkNavy,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(guest.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    Text('Guest ID: ${guest.guestId}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  _buildStatusBadge(guest),
                  const SizedBox(height: 16),
                  _buildSection('Personal Details', [
                    _buildRow(Icons.person_outline, 'First Name', guest.firstName),
                    _buildRow(Icons.person_outline, 'Last Name', guest.lastName),
                    _buildRow(Icons.flag_outlined, 'Nationality', guest.nationality ?? 'Not provided'),
                    _buildRow(Icons.cake_outlined, 'Date of Birth', guest.dateOfBirth != null ? DateFormat('MMM dd, yyyy').format(guest.dateOfBirth!) : 'Not provided'),
                    _buildRow(Icons.assignment_outlined, 'Passport / ID', guest.passport ?? 'Not provided'),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Contact', [
                    _buildRow(Icons.email_outlined, 'Email', guest.email),
                    _buildRow(Icons.phone_outlined, 'Phone', guest.phone ?? 'Not provided'),
                    _buildRow(Icons.home_outlined, 'Home Address', guest.homeAddress ?? 'Not provided'),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Account', [
                    _buildRow(Icons.qr_code, 'Guest ID', guest.guestId),
                    _buildRow(Icons.badge_outlined, 'Status', guest.status),
                    _buildRow(Icons.shield_outlined, 'Account Status', guest.accountStatus),
                    _buildRow(Icons.person_pin_outlined, 'Registered by', guest.createdByName ?? 'Self'),
                    _buildRow(Icons.calendar_month_outlined, 'Member Since', guest.createdAt != null ? DateFormat('MMM dd, yyyy').format(guest.createdAt!) : 'N/A'),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Quick Actions', [
                    _buildMenuItem(Icons.star_outline, 'Leave a Review', () => context.push('/feedback')),
                    _buildMenuItem(Icons.info_outline, 'Hotel Information', () => context.push('/hotel-info')),
                    if (reservationState.hasActiveReservation)
                      _buildMenuItem(Icons.calendar_month, 'My Reservations', () => context.push('/reservations')),
                    _buildMenuItem(Icons.settings_outlined, 'Settings', () => context.push('/settings')),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Preferences', [
                    SwitchListTile(
                      title: const Text('Dark Mode', style: TextStyle(fontSize: 15)),
                      secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.darkNavy),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  ref.read(authStateProvider.notifier).logout();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled, foregroundColor: Colors.white),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusCancelled,
                        side: const BorderSide(color: AppColors.statusCancelled),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic guest) {
    final isVip = guest.vip == true;
    final status = guest.status?.toString().toUpperCase() ?? 'RESERVED';
    Color statusColor;
    switch (status) {
      case 'CHECKED_IN':
        statusColor = AppColors.statusConfirmed;
      case 'CHECKED_OUT':
        statusColor = AppColors.textTertiary;
      default:
        statusColor = AppColors.statusPending;
    }

    return Row(
      children: [
        if (isVip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: AppColors.goldAccent),
                const SizedBox(width: 4),
                Text('VIP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.goldAccent)),
              ],
            ),
          ),
        if (isVip) const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.replaceAll('_', ' '),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ),
        const Spacer(),
        if (guest.notes != null && guest.notes!.isNotEmpty)
          Flexible(
            child: Text(
              guest.notes!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.3)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.darkNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkNavy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.darkNavy),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
