import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _methods = [
    {'type': 'Visa', 'last4': '4242', 'expiry': '12/26'},
    {'type': 'Mastercard', 'last4': '8888', 'expiry': '08/25'},
  ];

  void _deleteMethod(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Payment Method'),
        content: Text('Remove ${_methods[index]['type']} ending in ${_methods[index]['last4']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _methods.removeAt(index));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method removed'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: _methods.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.credit_card_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No payment methods saved', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _methods.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final m = _methods[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.darkNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(m['type'] == 'Visa' ? Icons.credit_card : Icons.credit_card, color: AppColors.darkNavy),
                    ),
                    title: Text('${m['type']} •••• ${m['last4']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Expires ${m['expiry']}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.statusCancelled),
                      onPressed: () => _deleteMethod(i),
                    ),
                  ),
                );
              },
            ),
    );
  }
}