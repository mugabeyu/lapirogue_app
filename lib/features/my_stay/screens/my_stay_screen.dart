import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

/// My Stay Screen - Shows guest personal, reservation and room information
class MyStayScreen extends StatefulWidget {
  const MyStayScreen({super.key});

  @override
  State<MyStayScreen> createState() => _MyStayScreenState();
}

class _MyStayScreenState extends State<MyStayScreen> {
  Map<String, dynamic>? _guestData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final guest = await SupabaseService.getCurrentGuest();
    if (mounted) {
      setState(() {
        _guestData = guest;
        _isLoading = false;
      });
    }
  }

  String get _guestName {
    final firstName = _guestData?['first_name'] ?? '';
    final lastName = _guestData?['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  String get _email => _guestData?['email'] ?? '--';
  String get _phone => _guestData?['phone'] ?? '--';
  String get _nationality => _guestData?['nationality'] ?? '--';
  String get _passport => _guestData?['passport'] ?? '--';

  Map<String, dynamic>? get _reservation {
    final reservations = _guestData?['reservations'];
    if (reservations != null && reservations is List && reservations.isNotEmpty) {
      return reservations[0];
    }
    return null;
  }

  String get _reservationId => _reservation?['reservation_id'] ?? '--';
  String get _checkInDate => _reservation?['check_in'] ?? '--';
  String get _checkOutDate => _reservation?['check_out'] ?? '--';
  String get _adults => (_reservation?['adults'] ?? 1).toString();
  String get _children => (_reservation?['children'] ?? 0).toString();
  String get _reservationStatus => _reservation?['status'] ?? 'CONFIRMED';

  Map<String, dynamic>? get _room {
    return _reservation?['rooms'];
  }

  String get _roomNumber => _room?['room_number'] ?? '--';
  String get _roomType => _room?['type'] ?? '--';
  String get _roomStatus => _room?['status'] ?? '--';
  
  List<String> get _amenities {
    final amenities = _room?['amenities'];
    if (amenities != null && amenities is List) {
      return amenities.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryLight,
                          ],
                        ),
                      ),
                    ),
                    title: const Text('My Stay'),
                  ),
                ),
                
                // Personal Information Section
                SliverToBoxAdapter(
                  child: _buildSection(
                    title: 'Personal Information',
                    icon: Icons.person,
                    content: Column(
                      children: [
                        _buildInfoRow('Full Name', _guestName),
                        _buildInfoRow('Email', _email),
                        _buildInfoRow('Phone', _phone),
                        _buildInfoRow('Nationality', _nationality),
                        _buildInfoRow('Passport', _passport),
                      ],
                    ),
                  ),
                ),
                
                // Reservation Information Section
                SliverToBoxAdapter(
                  child: _buildSection(
                    title: 'Reservation Information',
                    icon: Icons.confirmation_number,
                    content: Column(
                      children: [
                        _buildInfoRow('Reservation #', _reservationId),
                        _buildInfoRow('Status', _reservationStatus),
                        _buildInfoRow('Check-in', _checkInDate),
                        _buildInfoRow('Check-out', _checkOutDate),
                        _buildInfoRow('Adults', _adults),
                        _buildInfoRow('Children', _children),
                      ],
                    ),
                  ),
                ),
                
                // Room Information Section
                SliverToBoxAdapter(
                  child: _buildSection(
                    title: 'Room Information',
                    icon: Icons.hotel,
                    content: Column(
                      children: [
                        _buildInfoRow('Room Number', _roomNumber),
                        _buildInfoRow('Room Type', _roomType),
                        _buildInfoRow('Room Status', _roomStatus),
                        if (_amenities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Amenities:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _amenities.map((amenity) {
                              return Chip(
                                label: Text(
                                  amenity,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                side: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
