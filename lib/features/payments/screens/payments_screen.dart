import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/payment.dart';
import 'package:intl/intl.dart';

/// Payments & Billing Screen (Read-only)
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  double _totalPaid = 0;
  double _totalOutstanding = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final guestId = await GuestService().getCurrentGuestId();
    if (guestId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final payments = await PaymentService().getPayments(guestId);
      double paid = 0;
      double outstanding = 0;
      
      for (var payment in payments) {
        if (payment.status == 'COMPLETED' || payment.status == 'PAID') {
          paid += payment.amount;
        } else {
          outstanding += payment.amount;
        }
      }
      
      setState(() {
        _payments = payments;
        _totalPaid = paid;
        _totalOutstanding = outstanding;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading payments: $e');
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
              onRefresh: _loadPayments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Total Paid',
                            'Rs ${_totalPaid.toStringAsFixed(2)}',
                            AppTheme.accentGreen,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Outstanding',
                            'Rs ${_totalOutstanding.toStringAsFixed(2)}',
                            _totalOutstanding > 0 ? AppTheme.accentOrange : AppTheme.accentGreen,
                            _totalOutstanding > 0 ? Icons.pending : Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
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
