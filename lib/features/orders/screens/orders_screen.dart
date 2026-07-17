import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/session_service.dart';
import '../../../core/models/food_order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<FoodOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final guest = await SessionService.getCurrentGuest();
      if (guest == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('food_orders')
          .select('*')
          .eq('guest_id', guest['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = (response as List)
              .map((e) => FoodOrder.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.statusPending;
      case 'PREPARING':
        return AppColors.statusInfo;
      case 'SERVED':
        return AppColors.statusConfirmed;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.schedule;
      case 'PREPARING':
        return Icons.restaurant;
      case 'SERVED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _OrderCard(
                        order: order,
                        statusColor: _statusColor(order.status),
                        statusIcon: _statusIcon(order.status),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'No orders yet',
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your food and beverage orders will appear here.\nHead to Dining or Room Service to place one.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final FoodOrder order;
  final Color statusColor;
  final IconData statusIcon;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  String _formatTimeDisplay(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
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
                      color: widget.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.statusIcon,
                      color: widget.statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderId.isNotEmpty
                              ? 'Order #${order.orderId}'
                              : 'Order',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (order.scheduledDate != null && order.scheduledTime != null)
                          Text(
                            'Scheduled: ${DateFormat('MMM dd, yyyy').format(order.scheduledDate!)} – ${_formatTimeDisplay(order.scheduledTime!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else if (order.createdAt != null)
                          Text(
                            DateFormat('MMM dd, yyyy – hh:mm a')
                                .format(order.createdAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
              if (_expanded) ...[
                const Divider(height: 24),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name']?.toString() ?? 'Item',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        'x${item['quantity'] ?? 1}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'MUR ${(item['price'] ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'MUR ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${order.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
