import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/guest.dart';
import '../../../core/theme/app_theme.dart';

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
    if (mounted) {
      setState(() { _guest = guest; _isLoading = false; });
    }
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
            const SnackBar(content: Text('Profile photo updated successfully'), backgroundColor: AppTheme.accentGreen),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload photo'), backgroundColor: AppTheme.accentRed),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error: ');
    } finally {
      if (mounted) { setState(() => _isUploadingPhoto = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_guest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Unable to load profile')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isUploadingPhoto)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _guest!.imagePath != null ? NetworkImage(_guest!.imagePath!) : null,
                            child: _guest!.imagePath == null ? const Icon(Icons.person, size: 50) : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_guest!.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_guest!.email, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildInfoRow('Full Name', _guest!.fullName),
                    _buildInfoRow('Email', _guest!.email),
                    _buildInfoRow('Phone', _guest!.phone ?? '--'),
                    _buildInfoRow('Nationality', _guest!.nationality ?? '--'),
                    _buildInfoRow('Passport', _guest!.passport ?? '--'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_guest!.reservations?.isNotEmpty == true)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Reservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...() {
                        final reservation = _guest!.reservations![0];
                        return [
                          _buildInfoRow('Room', 'Room '),
                          _buildInfoRow('Room Type', reservation.room?.type ?? '--'),
                          _buildInfoRow('Check-in', reservation.checkIn.toIso8601String().split('T').first),
                          _buildInfoRow('Check-out', reservation.checkOut.toIso8601String().split('T').first),
                          _buildInfoRow('Status', reservation.status),
                        ];
                      }(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

