import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/reservation_gate.dart';
import '../../../core/models/activity.dart';
import '../../booking/screens/booking_screen.dart';

class SpaScreen extends ConsumerStatefulWidget {
  const SpaScreen({super.key});

  @override
  ConsumerState<SpaScreen> createState() => _SpaScreenState();
}

class _SpaScreenState extends ConsumerState<SpaScreen> {
  List<Activity> _treatments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    try {
      final response = await Supabase.instance.client
          .from('activities')
          .select('*')
          .eq('status', 'ACTIVE')
          .order('name');

      if (mounted) {
        setState(() {
          _treatments = (response as List)
              .map((e) => Activity.fromJson(e))
              .where((a) =>
                  a.category.toUpperCase() == 'SPA' ||
                  a.category.toUpperCase() == 'RELAXATION')
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _bookTreatment(Activity treatment) async {
    if (!mounted) return;
    context.push(
      '/booking',
      extra: BookingItem(
        type: BookingType.spa,
        id: treatment.id,
        name: treatment.name,
        imagePath: treatment.imagePath,
        price: treatment.price,
        category: treatment.category,
        description: treatment.description,
        duration: treatment.duration,
        capacity: treatment.capacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReservationGate(
      requiresCheckIn: true,
      checkInLockedTitle: 'Spa Available After Check-In',
      checkInLockedMessage:
          'Book spa treatments once you check in at the hotel.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Spa & Wellness'),
          backgroundColor: AppColors.darkNavy,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTreatments,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryLight.withValues(alpha: 0.85),
                                    AppColors.primaryDark,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.spa, color: Colors.white, size: 56),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Serenity Spa',
                                      style: AppTypography.heading.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Find your inner peace',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Our Treatments',
                              style: AppTypography.sectionTitle,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_treatments.length} ${_treatments.length == 1 ? 'treatment' : 'treatments'} available',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_treatments.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'No spa treatments available at this time.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ..._treatments.map(
                                (treatment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildTreatmentCard(treatment),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Text(
                              'Facilities',
                              style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'Steam Room', 'Sauna', 'Jacuzzi',
                                'Ice Fountain', 'Relaxation Lounge',
                                'Yoga Studio', 'Meditation Garden',
                              ].map(
                                (f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    f,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ).toList(),
                            ),
                            const SizedBox(height: 24),
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

  Widget _buildTreatmentCard(Activity treatment) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: treatment.imagePath != null && treatment.imagePath!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: treatment.imagePath!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.lightGray,
                        child: const Icon(Icons.spa, size: 56, color: AppColors.darkNavy),
                      ),
                      placeholder: (_, _) => Container(color: AppColors.lightGray),
                    )
                  : Container(
                      color: AppColors.lightGray,
                      child: const Icon(Icons.spa, size: 56, color: AppColors.darkNavy),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        treatment.name,
                        style: AppTypography.cardTitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MUR ${treatment.price.toStringAsFixed(0)}',
                      style: AppTypography.priceSmall.copyWith(
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${treatment.duration} min',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (treatment.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    treatment.description!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _bookTreatment(treatment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Book Treatment',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
