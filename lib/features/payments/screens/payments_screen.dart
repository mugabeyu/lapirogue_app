import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/payment.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  BillingSummary? _billing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        PaymentService().getPayments(guestId),
        BillingService().getBillingSummary(guestId),
      ]);
      
      setState(() {
        _payments = results[0] as List<Payment>;
        _billing = results[1] as BillingSummary;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading billing data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Billing')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Billing Summary
                    if (_billing != null) ...[
                      _buildBillingSummary(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Payments List
                    if (_payments.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('No payments found', style: TextStyle(color: AppTheme.textTertiary)),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._payments.map((payment) => _buildPaymentCard(payment)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBillingSummary() {
    if (_billing == null) return const SizedBox.shrink();
    final b = _billing!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Charges',
                'Rs ${b.totalCharges.toStringAsFixed(2)}',
                AppTheme.primary,
                Icons.receipt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Paid',
                'Rs ${b.totalPaid.toStringAsFixed(2)}',
                AppTheme.accentGreen,
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Balance Due',
                'Rs ${b.balanceDue.toStringAsFixed(2)}',
                b.balanceDue > 0 ? AppTheme.accentOrange : AppTheme.accentGreen,
                b.balanceDue > 0 ? Icons.pending : Icons.check_circle,
              ),
            ),
          ],
        ),
        if (b.totals.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...b.totals.entries
            .where((e) => e.value > 0)
            .map((e) => _buildBreakdownRow(e.key, e.value)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildBreakdownRow('Total', b.totalCharges, isTotal: true),
        ],
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final amount = payment.amount;
    final status = payment.status;
    final method = payment.method;
    final createdAt = payment.createdAt ?? DateTime.now();
    final paymentId = payment.paymentId;
    final extraItems = payment.extraItems;

    Color statusColor;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'PAID':
        statusColor = AppTheme.accentGreen;
        break;
      case 'PENDING':
        statusColor = AppTheme.accentOrange;
        break;
      case 'FAILED':
      case 'REFUNDED':
        statusColor = AppTheme.accentRed;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment #$paymentId',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy • HH:mm').format(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'Rs ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        children: [
          if (extraItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Additional Charges',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...extraItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['label']}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Rs ${(item['amount'] ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
