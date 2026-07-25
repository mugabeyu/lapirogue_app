import 'package:flutter/material.dart';
import '../../../core/services/content_service.dart';
import '../../../core/models/site_content_page.dart';
import '../../../core/models/hotel_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class HotelInfoScreen extends StatefulWidget {
  const HotelInfoScreen({super.key});

  @override
  State<HotelInfoScreen> createState() => _HotelInfoScreenState();
}

class _HotelInfoScreenState extends State<HotelInfoScreen> {
  SiteContentPage? _hotelInfo;
  List<HotelService> _services = [];
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
        ContentService().getHotelServices(),
      ]);

      setState(() {
        _hotelInfo = results[0] as SiteContentPage?;
        _services = results[1] as List<HotelService>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
      case 'warning': return Icons.warning;
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
                    if (_services.isNotEmpty) _buildServicesSection(),
                    if (_hotelInfo == null && _services.isEmpty)
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
              style: AppTypography.bodyLarge.copyWith(color: AppTheme.textTertiary),
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
                    style: AppTypography.display.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                if (info.subtitle != null && info.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      info.subtitle!,
                      style: AppTypography.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
                if (info.body != null && info.body!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    info.body!,
                    style: AppTypography.caption.copyWith(color: AppTheme.textSecondary),
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
                                style: AppTypography.caption.copyWith(color: AppTheme.textSecondary),
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
                                style: AppTypography.small.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['value']?.toString() ?? '',
                                style: AppTypography.sectionTitle.copyWith(color: AppTheme.primary),
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
                                style: AppTypography.small.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                parts[1].trim(),
                                style: AppTypography.sectionTitle.copyWith(color: AppTheme.primary),
                              ),
                            ],
                          ),
                        );
                      }
                      return Text(m.toString(), style: AppTypography.caption);
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
            style: AppTypography.sectionTitle,
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
                              Text(service.name, style: AppTypography.captionMedium),
                              if (service.description != null && service.description!.isNotEmpty)
                                Text(service.description!, style: AppTypography.caption.copyWith(color: AppTheme.textSecondary)),
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
          Text(text, style: AppTypography.caption.copyWith(color: AppTheme.textTertiary)),
        ],
      ),
    );
  }

}
