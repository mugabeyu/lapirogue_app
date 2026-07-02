import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/room.dart';
import '../../../data/providers/hotel_provider.dart';

class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});

  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  List<Room> _availableRooms = [];
  bool _isLoadingRooms = false;
  bool _hasSearched = false;

  Future<void> _pickDate(bool isCheckIn) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final first = isCheckIn ? DateTime.now() : _checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.oceanBlue, onPrimary: Colors.white, surface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
      _searchAvailableRooms();
    }
  }

  Future<void> _searchAvailableRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _hasSearched = true;
    });
    try {
      final checkInStr = DateFormat('yyyy-MM-dd').format(_checkIn);
      final checkOutStr = DateFormat('yyyy-MM-dd').format(_checkOut);
      final result = await Supabase.instance.client.rpc('get_available_rooms', params: {
        'p_check_in': checkInStr,
        'p_check_out': checkOutStr,
      });
      setState(() {
        _availableRooms = (result as List)
            .map((e) => Room.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      final allRooms = await ref.read(allRoomsProvider.future);
      final available = allRooms.where((r) => r.status == 'AVAILABLE').toList();
      setState(() => _availableRooms = available);
    }
    setState(() => _isLoadingRooms = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Room'),
        backgroundColor: AppColors.oceanBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton('Check-in', _checkIn, () => _pickDate(true)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, color: AppColors.textTertiary),
                    ),
                    Expanded(
                      child: _buildDateButton('Check-out', _checkOut, () => _pickDate(false)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingRooms ? null : _searchAvailableRooms,
                    icon: _isLoadingRooms
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search, size: 20),
                    label: Text(_isLoadingRooms ? 'Searching...' : 'Check Availability'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildRoomList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.oceanBlue),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Select your dates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Choose check-in and check-out dates\nto see available rooms', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_isLoadingRooms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No rooms available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Try different dates', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableRooms.length,
      itemBuilder: (context, index) {
        final room = _availableRooms[index];
        final nights = _checkOut.difference(_checkIn).inDays;
        final totalPrice = room.price * nights;
        return _buildRoomCard(context, room, nights, totalPrice);
      },
    );
  }

  Widget _buildRoomCard(BuildContext context, Room room, int nights, double totalPrice) {
    return GestureDetector(
      onTap: () => context.push('/rooms/${room.id}', extra: {
        'checkIn': DateFormat('yyyy-MM-dd').format(_checkIn),
        'checkOut': DateFormat('yyyy-MM-dd').format(_checkOut),
        'nights': nights,
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: room.imagePath ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: Colors.grey[200]),
                  errorWidget: (_, _, _) => Container(color: AppColors.lightGray, child: const Icon(Icons.image, size: 48, color: AppColors.textTertiary)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(room.type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.goldAccent)),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('MUR ${NumberFormat('#,###').format(room.price.toInt())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.oceanBlue)),
                          Text('per night', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(room.roomNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Up to ${room.capacity} guests', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  if (room.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: room.amenities.take(3).map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(a, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.oceanBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$nights nights', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        Text('MUR ${NumberFormat('#,###').format(totalPrice.toInt())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.oceanBlue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
