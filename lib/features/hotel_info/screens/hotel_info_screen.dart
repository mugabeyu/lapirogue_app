import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

/// Hotel Information Screen
class HotelInfoScreen extends StatefulWidget {
  const HotelInfoScreen({super.key});

  @override
  State<HotelInfoScreen> createState() => _HotelInfoScreenState();
}

class _HotelInfoScreenState extends State<HotelInfoScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final response = await SupabaseService.client
          .from('rooms')
          .select('*')
          .order('room_number');

      setState(() {
        _rooms = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading rooms: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'tv':
        return Icons.tv;
      case 'ac':
      case 'air conditioning':
        return Icons.ac_unit;
      case 'minibar':
        return Icons.local_bar;
      case 'safe':
        return Icons.security;
      case 'balcony':
        return Icons.balcony;
      case 'sea view':
      case 'ocean view':
        return Icons.water;
      case 'garden view':
        return Icons.yard;
      case 'pool access':
        return Icons.pool;
      case 'room service':
        return Icons.room_service;
      case 'hair dryer':
        return Icons.dry;
      case 'iron':
        return Icons.iron;
      case 'desk':
        return Icons.desk;
      case 'sofa':
        return Icons.chair;
      case 'bathtub':
        return Icons.bathtub;
      case 'shower':
        return Icons.shower;
      case 'coffee maker':
        return Icons.coffee;
      case 'kettle':
        return Icons.water_drop;
      case 'fridge':
      case 'refrigerator':
        return Icons.kitchen;
      case 'microwave':
        return Icons.microwave;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Information'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel Overview Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'La Pirogue',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Mauritius',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'A luxury beachfront resort offering world-class amenities and exceptional service. Experience the perfect blend of Mauritian hospitality and modern comfort.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildFeatureChip(Icons.wifi, 'Free WiFi'),
                                _buildFeatureChip(Icons.pool, 'Pool'),
                                _buildFeatureChip(Icons.restaurant, 'Restaurant'),
                                _buildFeatureChip(Icons.spa, 'Spa'),
                                _buildFeatureChip(Icons.fitness_center, 'Gym'),
                                _buildFeatureChip(Icons.beach_access, 'Beach'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rooms Section
                    const Text(
                      'Our Rooms',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_rooms.isEmpty)
                      const Center(child: Text('No rooms available'))
                    else
                      ..._rooms.map((room) => _buildRoomCard(room)),
                    const SizedBox(height: 24),

                    // Contact Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildContactRow(Icons.phone, '+230 123 4567'),
                            _buildContactRow(Icons.email, 'info@lapirogue.mu'),
                            _buildContactRow(Icons.location_on, 'Wolmar, Flic en Flac, Mauritius'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primary),
      label: Text(label),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final amenities = (room['amenities'] as List<dynamic>?)?.cast<String>() ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hotel, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room ${room['room_number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${room['type']} - Rs ${room['price']}/night',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text(
                  room['description'] ?? 'No description available',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Amenities:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: amenities.map((amenity) {
                      return Chip(
                        avatar: Icon(
                          _getAmenityIcon(amenity),
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        label: Text(amenity),
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
