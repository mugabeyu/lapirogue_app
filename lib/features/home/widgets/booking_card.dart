import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class BookingCard extends StatefulWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final ValueChanged<DateTime> onCheckInChanged;
  final ValueChanged<DateTime> onCheckOutChanged;
  final VoidCallback onSearch;

  const BookingCard({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onCheckInChanged,
    required this.onCheckOutChanged,
    required this.onSearch,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  Future<void> _pickDate(bool isCheckIn) async {
    final initial = isCheckIn ? widget.checkIn : widget.checkOut;
    final first = isCheckIn ? DateTime.now() : widget.checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (isCheckIn) {
        widget.onCheckInChanged(picked);
        if (widget.checkOut.isBefore(picked.add(const Duration(days: 1)))) {
          widget.onCheckOutChanged(picked.add(const Duration(days: 1)));
        }
      } else {
        widget.onCheckOutChanged(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField('Check-in', widget.checkIn, () => _pickDate(true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField('Check-out', widget.checkOut, () => _pickDate(false)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onSearch,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: AppTypography.captionMedium.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
