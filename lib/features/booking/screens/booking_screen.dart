import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/session_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/result_overlay.dart';
import '../../../data/providers/reservation_provider.dart';

enum BookingType { activity, dining, spa, roomService, customRequest }

class BookingItem {
  final BookingType type;
  final String id;
  final String name;
  final String? imagePath;
  final double price;
  final String? category;
  final String? description;
  final int? duration;
  final int? capacity;

  const BookingItem({
    required this.type,
    required this.id,
    required this.name,
    this.imagePath,
    required this.price,
    this.category,
    this.description,
    this.duration,
    this.capacity,
  });
}

class BookingScreen extends ConsumerStatefulWidget {
  final BookingItem item;

  const BookingScreen({super.key, required this.item});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late DateTime _selectedDate;
  late String _selectedTime;
  int _participants = 1;
  bool _isSubmitting = false;
  DateTime? _stayStart;
  DateTime? _stayEnd;

  static const _timeSlots = [
    '09:00 AM', '10:30 AM', '12:00 PM', '02:00 PM',
    '04:00 PM', '04:30 PM', '06:00 PM',
  ];

  static const _pickupPoints = [
    'Hotel Lobby', 'Beach Hut', 'Pool Deck', 'Marina Pier',
  ];

  String _pickupPoint = 'Hotel Lobby';
  int _quantity = 1;

  final _requestTitleController = TextEditingController();
  final _requestNotesController = TextEditingController();

  bool get _isCustom => widget.item.type == BookingType.customRequest;

  @override
  void initState() {
    super.initState();
    final reservation =
        ref.read(reservationProvider).activeReservation;
    if (reservation != null) {
      _stayStart = reservation.checkIn;
      _stayEnd = reservation.checkOut;
      _selectedDate = reservation.checkIn.isAfter(DateTime.now())
          ? reservation.checkIn
          : DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
    _selectedTime = _timeSlots[0];
  }

  @override
  void dispose() {
    _requestTitleController.dispose();
    _requestNotesController.dispose();
    super.dispose();
  }

  String _itemTypeLabel() {
    switch (widget.item.type) {
      case BookingType.activity:
        return 'Book Activity';
      case BookingType.dining:
        return 'Order Food';
      case BookingType.spa:
        return 'Book Treatment';
      case BookingType.roomService:
        return 'Order Room Service';
      case BookingType.customRequest:
        return 'Custom Request';
    }
  }

  String _confirmLabel() {
    switch (widget.item.type) {
      case BookingType.activity:
        return 'Confirm Booking';
      case BookingType.dining:
        return 'Place Order';
      case BookingType.spa:
        return 'Book Treatment';
      case BookingType.roomService:
        return 'Place Order';
      case BookingType.customRequest:
        return 'Submit Request';
    }
  }

  IconData _confirmIcon() {
    switch (widget.item.type) {
      case BookingType.activity:
        return Icons.event_available;
      case BookingType.dining:
        return Icons.restaurant;
      case BookingType.spa:
        return Icons.spa;
      case BookingType.roomService:
        return Icons.room_service;
      case BookingType.customRequest:
        return Icons.send;
    }
  }

  Future<void> _pickDate() async {
    final first = _stayStart ?? DateTime.now();
    final last = _stayEnd ?? first.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.darkNavy,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final guest = await SessionService.getCurrentGuest();
      if (guest == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to book.')),
          );
        }
        return;
      }

      final guestId = guest['id'].toString();
      final supabase = Supabase.instance.client;

      switch (widget.item.type) {
        case BookingType.activity:
        case BookingType.spa:
          await _submitActivityBooking(guestId, supabase);
        case BookingType.dining:
        case BookingType.roomService:
          await _submitFoodOrder(guestId, supabase);
        case BookingType.customRequest:
          await _submitCustomRequest(guestId, supabase);
      }

      if (!mounted) return;
      await showResultOverlay(
        context,
        success: true,
        title: '${_itemTypeLabel()} confirmed',
        message: 'You will find it under My Stay, and reception has been notified.',
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) {
        await showResultOverlay(
          context,
          success: false,
          title: 'Booking not completed',
          message: 'Something went wrong on our side. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitActivityBooking(
    String guestId,
    SupabaseClient supabase,
  ) async {
    final time24 = _parseTimeSlot(_selectedTime);
    final dateStr = _selectedDate.toIso8601String().split('T').first;

    await supabase
        .from('activity_bookings')
        .insert({
          'activity_id': widget.item.id,
          'guest_id': guestId,
          'booking_date': dateStr,
          'booking_time': time24,
          'participants': _participants,
          'pickup_point': _pickupPoint,
          'status': 'CONFIRMED',
          'origin': 'MOBILE_APP',
        })
        .select('id')
        .single();
  }

  Future<void> _submitFoodOrder(
    String guestId,
    SupabaseClient supabase,
  ) async {
    final total = widget.item.price * _quantity;
    final time24 = _parseTimeSlot(_selectedTime);
    final dateStr = _selectedDate.toIso8601String().split('T').first;

    final reservation = await supabase
        .from('reservations')
        .select('room_id, status')
        .eq('guest_id', guestId)
        .neq('status', 'CANCELLED')
        .order('check_in', ascending: false)
        .limit(1)
        .maybeSingle();

    if (reservation == null || reservation['status'] != 'CHECKED_IN') {
      throw Exception('Guest must be checked in before placing food orders.');
    }

    await supabase
        .from('food_orders')
        .insert({
          'guest_id': guestId,
          'room_id': reservation['room_id'],
          'items': [
            {
              'id': widget.item.id,
              'name': widget.item.name,
              'quantity': _quantity,
              'price': widget.item.price,
            },
          ],
          'subtotal': total,
          'service_charge': 0,
          'tax_amount': 0,
          'total': total,
          'status': 'PENDING',
          'origin': 'MOBILE_APP',
          'scheduled_date': dateStr,
          'scheduled_time': time24,
        })
        .select('id')
        .single();
  }

  Future<void> _submitCustomRequest(
    String guestId,
    SupabaseClient supabase,
  ) async {
    final title = _requestTitleController.text.trim();
    if (title.isEmpty) {
      throw Exception('Please enter a title for your request.');
    }

    final time24 = _parseTimeSlot(_selectedTime);
    final parts = time24.split(':');
    final startAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    await supabase
        .from('guest_schedule_items')
        .insert({
          'guest_id': guestId,
          'title': title,
          'item_type': 'CUSTOM',
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': startAt.add(const Duration(hours: 1)).toUtc().toIso8601String(),
          'description': _requestNotesController.text.trim(),
          'status': 'SCHEDULED',
          'color': '#E7D7F0',
          'source_module': 'guest_app',
        })
        .select('id')
        .single();
  }

  String _parseTimeSlot(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
            caseSensitive: false)
        .firstMatch(trimmed);
    if (match == null) return '$trimmed:00';
    int hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final ampm = match.group(3)?.toUpperCase();
    if (ampm == 'PM' && hour != 12) hour += 12;
    if (ampm == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute:00';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final needsTime = item.type == BookingType.activity ||
        item.type == BookingType.spa ||
        item.type == BookingType.dining ||
        item.type == BookingType.roomService;
    final needsPickup = item.type == BookingType.activity;
    final usesParticipants = item.type == BookingType.activity ||
        item.type == BookingType.spa;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          _itemTypeLabel(),
          style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isCustom) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imagePath != null && item.imagePath!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            item.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 200,
                              color: AppColors.lightGray,
                              child: Center(
                                child: Icon(
                                  _itemIcon(),
                                  size: 56,
                                  color: AppColors.darkNavy.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _itemIcon(),
                            size: 56,
                            color: AppColors.darkNavy.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTypography.sectionTitle.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'MUR ${item.price.toStringAsFixed(0)}',
                                style: AppTypography.priceSmall.copyWith(
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ],
                          ),
                          if (item.category != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.category!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (item.description != null &&
                              item.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              item.description!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGray2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: AppColors.darkNavy.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'What do you need?',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit a custom request for room service, extra amenities, or anything else.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    _isCustom ? 'Request Details' : 'Booking Details',
                    style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (_isCustom) ...[
                    _buildTextField(
                      controller: _requestTitleController,
                      label: 'Title',
                      hint: 'e.g. Room service, extra towels, cleaning...',
                      icon: Icons.title,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _requestNotesController,
                      label: 'Description (optional)',
                      hint: 'Provide any details or special instructions',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildDateSelector(),
                  if (needsTime) ...[
                    const SizedBox(height: 12),
                    _buildTimeSelector(),
                  ],
                  if (usesParticipants) ...[
                    const SizedBox(height: 12),
                    _buildCounter(
                      'Participants',
                      _participants,
                      1,
                      item.capacity ?? 20,
                      (v) => setState(() => _participants = v),
                    ),
                  ] else if (!_isCustom) ...[
                    const SizedBox(height: 12),
                    _buildCounter(
                      'Quantity',
                      _quantity,
                      1,
                      20,
                      (v) => setState(() => _quantity = v),
                    ),
                  ],
                  if (needsPickup) ...[
                    const SizedBox(height: 12),
                    _buildPickupSelector(),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (_stayStart != null && _stayEnd != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.darkNavy.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.darkNavy.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your stay: ${DateFormat('MMM dd').format(_stayStart!)} - ${DateFormat('MMM dd, yyyy').format(_stayEnd!)}',
                        style: AppTypography.caption.copyWith(color: AppColors.darkNavy.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.lightGray2)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitBooking,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_confirmIcon(), size: 20),
              label: Text(
                _isSubmitting
                    ? 'Processing...'
                    : _isCustom
                        ? _confirmLabel()
                        : '${_confirmLabel()} · MUR ${_totalPrice.toStringAsFixed(0)}',
                style: AppTypography.cardTitle,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get _totalPrice {
    final item = widget.item;
    final usesParticipants = item.type == BookingType.activity ||
        item.type == BookingType.spa;
    return item.price * (usesParticipants ? _participants : _quantity);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, color: AppColors.darkNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                labelStyle: AppTypography.small.copyWith(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _itemIcon() {
    switch (widget.item.type) {
      case BookingType.activity:
        return Icons.tour;
      case BookingType.dining:
        return Icons.restaurant;
      case BookingType.spa:
        return Icons.spa;
      case BookingType.roomService:
        return Icons.room_service;
      case BookingType.customRequest:
        return Icons.add_circle_outline;
    }
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: _pickDate,
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.darkNavy, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: AppTypography.small.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.darkNavy, size: 20),
          const SizedBox(width: 12),
          Text(
            'Time',
            style: AppTypography.small.copyWith(color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTime,
                isExpanded: true,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                items: _timeSlots.map((slot) {
                  return DropdownMenuItem(value: slot, child: Text(slot));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTime = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.darkNavy, size: 20),
          const SizedBox(width: 12),
          Text(
            'Pickup',
            style: AppTypography.small.copyWith(color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _pickupPoint,
                isExpanded: true,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                items: _pickupPoints.map((point) {
                  return DropdownMenuItem(value: point, child: Text(point));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _pickupPoint = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: AppColors.darkNavy, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            color: AppColors.textTertiary,
            iconSize: 22,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              style: AppTypography.cardTitle,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            color: AppColors.darkNavy,
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}
