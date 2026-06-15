import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/models/eco_points_transaction.dart';
import '../../../core/theme/app_theme.dart';
import 'leaderboard_screen.dart';

class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({super.key});

  @override
  State<SustainabilityScreen> createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen> {
  int _points = 0;
  String _tier = 'Bronze';
  List<EcoPointsTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final guestId = await SupabaseService.getCurrentGuestId();
    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        EcoPointsService().getEcoPointsBalance(guestId),
        EcoPointsService().getEcoPointsTier(guestId),
        EcoPointsService().getTransactions(guestId),
      ]);

      setState(() {
        _points = results[0] as int;
        _tier = results[1] as String;
        _transactions = results[2] as List<EcoPointsTransaction>;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading eco data: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTxIcon(String type) {
    switch (type.toUpperCase()) {
      case 'EARN':
        return Icons.add_circle;
      case 'SPEND':
        return Icons.remove_circle;
      case 'ADJUST':
        return Icons.sync;
      default:
        return Icons.circle;
    }
  }

  Color _getTxColor(String type) {
    switch (type.toUpperCase()) {
      case 'EARN':
        return AppTheme.accentGreen;
      case 'SPEND':
        return AppTheme.accentRed;
      case 'ADJUST':
        return AppTheme.accentOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _navigateToLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainability Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: _navigateToLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your Eco Points',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: _getTierColor(_tier),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_tier Tier',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                              'How to Earn Points',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildEarnOption(
                              icon: Icons.replay,
                              title: 'Reuse towels',
                              points: 10,
                            ),
                            _buildEarnOption(
                              icon: Icons.local_drink,
                              title: 'Use refillable water bottle',
                              points: 15,
                            ),
                            _buildEarnOption(
                              icon: Icons.recycling,
                              title: 'Participate in recycling',
                              points: 20,
                            ),
                            _buildEarnOption(
                              icon: Icons.electric_bolt,
                              title: 'Turn off lights when leaving',
                              points: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_transactions.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._transactions.take(5).map((tx) => _buildTransactionCard(tx)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEarnOption({
    required IconData icon,
    required String title,
    required int points,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$points',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(EcoPointsTransaction tx) {
    final type = tx.txType;
    final points = tx.points;
    final description = tx.description ?? 'Activity';
    final createdAt = tx.createdAt ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTxColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getTxIcon(type), color: _getTxColor(type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${type == 'EARN' ? '+' : '-'}$points',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getTxColor(type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}