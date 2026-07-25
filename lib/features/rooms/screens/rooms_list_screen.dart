import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/room.dart';
import '../../../data/providers/hotel_provider.dart';
import '../../../core/theme/app_typography.dart';

class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});

  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

enum _SortOrder { priceLowToHigh, priceHighToLow, defaultOrder }

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  List<Room> _availableRooms = [];
  bool _isLoadingRooms = true;
  bool _hasSearched = true;
  _SortOrder _sortOrder = _SortOrder.priceLowToHigh;

  @override
  void initState() {
    super.initState();
    _loadAllAvailableRooms();
  }

  Future<void> _loadAllAvailableRooms() async {
    try {
      final allRooms = await ref.read(allRoomsProvider.future);
      if (mounted) {
        setState(() {
          _availableRooms = allRooms.where((r) => r.status == 'AVAILABLE').toList();
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  List<Room> get _sortedRooms {
    final sorted = List<Room>.from(_availableRooms);
    switch (_sortOrder) {
      case _SortOrder.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case _SortOrder.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case _SortOrder.defaultOrder:
        break;
    }
    return sorted;
  }

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
          colorScheme: ColorScheme.light(primary: AppColors.darkNavy, onPrimary: Colors.white, surface: Colors.white),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rooms & Suites'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.lightGray2)),
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd').format(date),
                  style: AppTypography.bodyMedium,
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
            Text('Select your dates', style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Choose check-in and check-out dates\nto see available rooms', textAlign: TextAlign.center, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
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
            Text('No rooms available', style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Try different dates', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSortSelector(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _sortedRooms.length,
            itemBuilder: (context, index) {
              final room = _sortedRooms[index];
              final nights = _checkOut.difference(_checkIn).inDays;
              final totalPrice = room.price * nights;
              return _buildRoomCard(context, room, nights, totalPrice);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('Sort by', style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          DropdownButton<_SortOrder>(
            value: _sortOrder,
            isDense: true,
            underline: const SizedBox(),
            style: AppTypography.caption.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w500),
            items: const [
              DropdownMenuItem(value: _SortOrder.priceLowToHigh, child: Text('Price (Low to High)')),
              DropdownMenuItem(value: _SortOrder.priceHighToLow, child: Text('Price (High to Low)')),
              DropdownMenuItem(value: _SortOrder.defaultOrder, child: Text('Default Order')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _sortOrder = value);
            },
          ),
        ],
      ),
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
          border: Border.all(color: AppColors.lightGray2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
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
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(room.type, style: AppTypography.overline.copyWith(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Room ${room.roomNumber}', style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(room.type, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('MUR ${NumberFormat('#,###').format(room.price.toInt())}', style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text('per night', style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Up to ${room.capacity} guests', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  if (room.amenities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: room.amenities.take(3).map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(a, style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$nights nights', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                        Text('MUR ${NumberFormat('#,###').format(totalPrice.toInt())}', style: AppTypography.cardTitle.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
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
