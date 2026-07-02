import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/reservation_gate.dart';

class SpaScreen extends ConsumerWidget {
  const SpaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReservationGate(
      requiresCheckIn: true,
      checkInLockedTitle: 'Spa Available After Check-In',
      checkInLockedMessage:
          'Book spa treatments once you check in at the hotel.',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Spa & Wellness'),
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
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
                      const Color(0xFF9C27B0).withValues(alpha: 0.6),
                      const Color(0xFF7B1FA2),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa, color: Colors.white, size: 56),
                      const SizedBox(height: 8),
                      const Text(
                        'Serenity Spa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
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
              const Text(
                'Our Treatments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildTreatmentCard(
                'Moroccan Hammam',
                '60 min',
                'MUR 2,500',
                Icons.water_drop,
              ),
              _buildTreatmentCard(
                'Deep Tissue Massage',
                '90 min',
                'MUR 3,200',
                Icons.self_improvement,
              ),
              _buildTreatmentCard(
                'Facial Rejuvenation',
                '60 min',
                'MUR 2,800',
                Icons.face,
              ),
              _buildTreatmentCard(
                'Aromatherapy',
                '60 min',
                'MUR 2,200',
                Icons.air,
              ),
              _buildTreatmentCard(
                'Hot Stone Therapy',
                '90 min',
                'MUR 3,500',
                Icons.whatshot,
              ),
              _buildTreatmentCard(
                'Couples Massage',
                '90 min',
                'MUR 5,800',
                Icons.favorite,
              ),
              const SizedBox(height: 24),
              const Text(
                'Facilities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          'Steam Room',
                          'Sauna',
                          'Jacuzzi',
                          'Ice Fountain',
                          'Relaxation Lounge',
                          'Yoga Studio',
                          'Meditation Garden',
                        ]
                        .map(
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
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentCard(
    String name,
    String duration,
    String price,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF9C27B0), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  duration,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.oceanBlue,
            ),
          ),
        ],
      ),
    );
  }
}
