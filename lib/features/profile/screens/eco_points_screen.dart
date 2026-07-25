import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/eco_action.dart';
import '../../../core/models/eco_points_transaction.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class EcoPointsScreen extends StatefulWidget {
  const EcoPointsScreen({super.key});

  @override
  State<EcoPointsScreen> createState() => _EcoPointsScreenState();
}

class _EcoPointsScreenState extends State<EcoPointsScreen> {
  final _ecoService = EcoPointsService();
  int _balance = 0;
  String _tier = 'Bronze';
  double _carbonOffsetKg = 0;
  List<EcoPointsTransaction> _transactions = [];
  List<EcoAction> _ecoActions = [];
  String? _guestId;
  bool _isLoading = true;
  String? _loggingActionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final results = await Future.wait([
      _ecoService.getEcoPointsBalance(guestId),
      _ecoService.getEcoPointsTier(guestId),
      _ecoService.getTransactions(guestId),
      _ecoService.getEcoActions(),
    ]);
    if (!mounted) return;
    final transactions = results[2] as List<EcoPointsTransaction>;
    setState(() {
      _guestId = guestId;
      _balance = results[0] as int;
      _tier = results[1] as String;
      _transactions = transactions;
      _ecoActions = results[3] as List<EcoAction>;
      _carbonOffsetKg = transactions.fold(0, (sum, t) => sum + (t.carbonOffsetKg ?? 0));
      _isLoading = false;
    });
  }

  Future<void> _logAction(EcoAction action) async {
    final guestId = _guestId;
    if (guestId == null) return;
    setState(() => _loggingActionId = action.id);
    final success = await _ecoService.participateInEcoAction(guestId: guestId, actionId: action.id);
    if (!mounted) return;
    setState(() => _loggingActionId = null);
    if (success) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '+${action.defaultPoints} eco-points${action.carbonOffsetKg != null ? ' · ${action.carbonOffsetKg!.toStringAsFixed(1)}kg CO₂ offset' : ''} for "${action.name}"',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.statusConfirmed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We couldn\'t log that action. Please try again.', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Eco-Points & Rewards'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.ecoGreenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.eco, size: 36, color: AppColors.ecoGreen),
                        const SizedBox(height: 12),
                        Text('$_balance', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.ecoGreen)),
                        const SizedBox(height: 4),
                        const Text('Eco-Points balance', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                          child: Text('$_tier tier', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ecoGreen)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.co2, size: 16, color: AppColors.ecoGreen),
                            const SizedBox(width: 6),
                            Text(
                              '${_carbonOffsetKg.toStringAsFixed(1)}kg CO₂ offset so far',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ecoGreen),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Log an eco-friendly action', style: AppTypography.sectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    'Each action earns points and a real carbon offset, tracked live for the hotel too.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_ecoActions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No eco actions available right now', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ..._ecoActions.map((action) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lightGray2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(action.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '+${action.defaultPoints} pts'
                                      '${action.carbonOffsetKg != null ? ' · ${action.carbonOffsetKg!.toStringAsFixed(1)}kg CO₂' : ''}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: _loggingActionId == action.id ? null : () => _logAction(action),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.ecoGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _loggingActionId == action.id
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('I did this', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 24),
                  const Text('History', style: AppTypography.sectionTitle),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No eco-points activity yet', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ..._transactions.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lightGray2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.ecoGreenLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.eco, size: 18, color: AppColors.ecoGreen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.sourceLabel ?? t.sourceType, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                    if (t.earnedAt != null)
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(t.earnedAt!) +
                                            ((t.carbonOffsetKg ?? 0) > 0 ? ' · ${t.carbonOffsetKg!.toStringAsFixed(1)}kg CO₂' : ''),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              Text('+${t.points}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ecoGreen)),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
