import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../core/theme/app_typography.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _ecoService = EcoPointsService();
  int _ecoPoints = 0;
  double _carbonOffsetKg = 0;
  bool _statsLoaded = false;
  String? _statsGuestId;

  Future<void> _loadStats(String guestId) async {
    if (_statsGuestId == guestId && _statsLoaded) return;
    _statsGuestId = guestId;
    final balance = await _ecoService.getEcoPointsBalance(guestId);
    final transactions = await _ecoService.getTransactions(guestId);
    final totalOffset = transactions.fold<double>(
      0,
      (sum, t) => sum + (t.carbonOffsetKg ?? 0),
    );
    if (!mounted) return;
    setState(() {
      _ecoPoints = balance;
      _carbonOffsetKg = totalOffset;
      _statsLoaded = true;
    });
  }

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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray2, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Profile Photo', style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUpload(context, ref, guestId, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We couldn\'t update your photo. Please try again.', style: TextStyle(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We couldn\'t remove your photo. Please try again.', style: TextStyle(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

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
                Text('My Profile', style: AppTypography.heading.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Sign in to manage your profile and preferences', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
    final reservationState = ref.watch(reservationProvider);
    final activeStaysCount = reservationState.reservations
        .where((r) => ['RESERVED', 'CONFIRMED', 'CHECKED_IN'].contains(r.status.toUpperCase()))
        .length;

    _loadStats(guest.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Avatar + name + status ──
          Row(
            children: [
              GestureDetector(
                onTap: () => _showPhotoOptions(context, ref, guest.id),
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: guest.imagePath != null
                            ? DecorationImage(image: NetworkImage(guest.imagePath!), fit: BoxFit.cover)
                            : null,
                        color: AppColors.primary,
                      ),
                      child: guest.imagePath == null
                          ? Center(
                              child: Text(
                                '${guest.firstName[0]}${guest.lastName[0]}',
                                style: AppTypography.heading.copyWith(color: Colors.white),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guest.fullName, style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(guest.email, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    _buildStatusBadge(guest),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Stats row ──
          Row(
            children: [
              Expanded(child: _StatBox(value: _statsLoaded ? '$_ecoPoints' : '—', label: 'Eco-Points')),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(value: '$activeStaysCount', label: 'Active stays')),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(value: _statsLoaded ? '${_carbonOffsetKg.toStringAsFixed(0)}kg' : '—', label: 'CO₂ offset')),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection('Quick links', [
            _buildMenuItem(Icons.calendar_today_outlined, 'My reservations', () => context.push('/reservations')),
            _buildMenuItem(Icons.eco_outlined, 'Eco-Points & rewards', () => context.push('/eco-points')),
            _buildMenuItem(Icons.receipt_long_outlined, 'Payments & billing', () => context.push('/payments')),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
            _buildMenuItem(Icons.info_outline, 'Hotel information', () => context.push('/hotel-info')),
            _buildMenuItem(Icons.settings_outlined, 'Settings', () => context.push('/settings')),
            _buildMenuItem(Icons.logout, 'Log out', () => _confirmSignOut(context, ref)),
          ]),
          const SizedBox(height: 12),
          _buildSection('Personal details', [
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
          Center(
            child: Text('La Pirogue Guest App', style: AppTypography.small.copyWith(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled, foregroundColor: Colors.white),
            child: const Text('Log out'),
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
        statusColor = AppColors.statusNeutral;
      default:
        statusColor = AppColors.statusPending;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppColors.statusPendingBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 12, color: AppColors.statusPending),
                const SizedBox(width: 3),
                Text('VIP', style: AppTypography.overline.copyWith(color: AppColors.statusPending)),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status.replaceAll('_', ' '),
            style: AppTypography.overline.copyWith(color: statusColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: AppTypography.captionMedium.copyWith(color: AppColors.textTertiary)),
          ),
          ...children,
          const SizedBox(height: 4),
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
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
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
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray2),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.sectionTitle.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.small.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
