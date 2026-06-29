import 'package:flutter/material.dart';
import '../../../core/services/content_service.dart';
import '../../../core/models/site_content_page.dart';
import '../../../core/models/room.dart';
import '../../../core/models/hotel_service.dart';
import '../../../core/models/hotel_service_category.dart';
import '../../../core/models/emergency_contact.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class HotelInfoScreen extends StatefulWidget {
  const HotelInfoScreen({super.key});

  @override
  State<HotelInfoScreen> createState() => _HotelInfoScreenState();
}

class _HotelInfoScreenState extends State<HotelInfoScreen> {
  SiteContentPage? _hotelInfo;
  List<Room> _rooms = [];
  List<HotelServiceCategory> _categories = [];
  List<HotelService> _services = [];
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ContentService().getPage('about'),
        _loadRooms(),
        ContentService().getServiceCategories(),
        ContentService().getHotelServices(),
        ContentService().getEmergencyContacts(),
      ]);

      setState(() {
        _hotelInfo = results[0] as SiteContentPage?;
        _rooms = results[1] as List<Room>;
        _categories = results[2] as List<HotelServiceCategory>;
        _services = results[3] as List<HotelService>;
        _emergencyContacts = results[4] as List<EmergencyContact>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Room>> _loadRooms() async {
    try {
      final response = await SupabaseService.client
          .from('rooms')
          .select('*')
          .order('room_number');
      return response.map((e) => Room.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  IconData _iconFromName(String? name) {
    switch ((name ?? '').toLowerCase()) {
      case 'wifi': return Icons.wifi;
      case 'pool': return Icons.pool;
      case 'restaurant': return Icons.restaurant;
      case 'spa': return Icons.spa;
      case 'gym':
      case 'fitness': return Icons.fitness_center;
      case 'beach': return Icons.beach_access;
      case 'phone':
      case 'reception':
      case 'front desk': return Icons.phone;
      case 'email': return Icons.email;
      case 'location':
      case 'location_on': return Icons.location_on;
      case 'concierge': return Icons.support_agent;
      case 'info': return Icons.info;
      case 'warning':
      case 'emergency': return Icons.warning;
      case 'medical':
      case 'hospital': return Icons.local_hospital;
      case 'fire':
      case 'fire_extinguisher': return Icons.fire_extinguisher;
      case 'security':
      case 'police': return Icons.security;
      case 'water': return Icons.water_drop;
      case 'eco': return Icons.eco;
      default: return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hotelInfo != null) _buildAboutSection(),
                    if (_rooms.isNotEmpty) _buildRoomsSection(),
                    if (_categories.isNotEmpty || _services.isNotEmpty)
                      _buildServicesSection(),
                    if (_emergencyContacts.isNotEmpty)
                      _buildEmergencySection(),
                    if (_hotelInfo == null &&
                        _rooms.isEmpty &&
                        _categories.isEmpty &&
                        _services.isEmpty &&
                        _emergencyContacts.isEmpty)
                      _buildEmptyState(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.hotel_class, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Hotel information coming soon',
              style: TextStyle(fontSize: 16, color: AppTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    final info = _hotelInfo!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.imagePath != null && info.imagePath!.isNotEmpty)
            Image.network(
              info.imagePath!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    info.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                if (info.subtitle != null && info.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      info.subtitle!,
                      style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
                if (info.body != null && info.body!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    info.body!,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                  ),
                ],
                if (info.highlights.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: info.highlights.map<Widget>((h) {
                      if (h is Map<String, dynamic>) {
                        return Chip(
                          avatar: Icon(
                            _iconFromName(h['icon']),
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          label: Text(h['label'] ?? ''),
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppTheme.accentGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h.toString(),
                                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (info.metrics.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: info.metrics.map<Widget>((m) {
                      if (m is Map<String, dynamic>) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                m['label']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['value']?.toString() ?? '',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        );
                      }
                      final parts = m.toString().split('|');
                      if (parts.length == 2) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                parts[0].trim(),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                parts[1].trim(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        );
                      }
                      return Text(m.toString(), style: const TextStyle(fontSize: 14));
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

  Widget _buildRoomsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Rooms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._rooms.map((room) => _buildRoomCard(room)),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final imageUrl = room.imagePaths.isNotEmpty
        ? room.imagePaths.first
        : room.imagePath;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 100,
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.hotel, size: 48, color: AppTheme.primary),
              ),
            )
          else
            Container(
              height: 100,
              color: AppTheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.hotel, size: 48, color: AppTheme.primary),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room ${room.roomNumber} - ${room.type}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Rs ${room.price.toStringAsFixed(0)}/night',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                if (room.description != null && room.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    room.description!,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (room.capacity > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Up to ${room.capacity} guests',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (room.amenities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities.map((amenity) {
                      return Chip(
                        avatar: Icon(_iconFromName(amenity), size: 14, color: AppTheme.primary),
                        label: Text(amenity, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
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

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hotel Services',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _services.map((service) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFromName(service.name), size: 20, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              if (service.description != null && service.description!.isNotEmpty)
                                Text(service.description!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                              if (service.phoneNumber != null && service.phoneNumber!.isNotEmpty)
                                _buildDetailRow(Icons.phone, service.phoneNumber!),
                              if (service.email != null && service.email!.isNotEmpty)
                                _buildDetailRow(Icons.email, service.email!),
                              if (service.location != null && service.location!.isNotEmpty)
                                _buildDetailRow(Icons.location_on, service.location!),
                              if (service.hoursText != null && service.hoursText!.isNotEmpty)
                                _buildDetailRow(Icons.access_time, service.hoursText!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Contacts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._emergencyContacts.map((contact) {
            final color = _parseHexColor(contact.colorHex);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFromName(contact.iconName), color: color, size: 24),
                ),
                title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contact.description.isNotEmpty)
                      Text(contact.description, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(contact.phoneNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (contact.is24h) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('24/7', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
