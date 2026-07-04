import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/auth_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/room.dart';
import '../../../core/widgets/auth_sheet.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/hotel_provider.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _adults = 2;
  int _children = 0;
  bool _booking = false;
  bool _extrasRead = false;

  @override
  void initState() {
    super.initState();
    _checkIn = DateTime.now().add(const Duration(days: 1));
    _checkOut = _checkIn.add(const Duration(days: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_extrasRead) return;
    _extrasRead = true;
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null) {
      if (extra['checkIn'] != null) {
        _checkIn = DateTime.parse(extra['checkIn'] as String);
      }
      if (extra['checkOut'] != null) {
        _checkOut = DateTime.parse(extra['checkOut'] as String);
      }
    }
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final first = isCheckIn
        ? DateTime.now().add(const Duration(days: 1))
        : _checkIn.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    }
  }

  Future<String> _requestReservationVerification(
    Room room,
    String guestId,
    String guestEmail,
    String checkInStr,
    String checkOutStr,
  ) async {
    final baseUrl = await AuthService().baseUrl;
    final totalAmount = room.price * _checkOut.difference(_checkIn).inDays;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/reservations/request-verification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'guestId': guestId,
              'roomId': room.id,
              'checkIn': checkInStr,
              'checkOut': checkOutStr,
              'adults': _adults,
              'children': _children,
              'totalAmount': totalAmount,
              'origin': 'MOBILE_APP',
              'email': guestEmail,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Request timed out after 30 seconds'),
          );

      // Check if response is JSON or HTML (error page)
      if (response.body.trimLeft().startsWith('<')) {
        throw Exception(
          'Backend returned HTML error (HTTP ${response.statusCode}). '
          'Server may be down or endpoint not found. '
          'Check backend URL: $baseUrl',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400 || payload['success'] != true) {
        throw Exception(
          payload['error'] ??
              'Failed to send verification code '
                  '(HTTP ${response.statusCode})',
        );
      }

      return (payload['data'] as Map<String, dynamic>)['verificationToken']
          as String;
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleBooking(
    Room room,
    String guestId,
    String guestEmail,
  ) async {
    setState(() => _booking = true);
    try {
      final checkInStr = _checkIn.toIso8601String().split('T').first;
      final checkOutStr = _checkOut.toIso8601String().split('T').first;
      final verificationId = await _requestReservationVerification(
        room,
        guestId,
        guestEmail,
        checkInStr,
        checkOutStr,
      );

      if (!mounted) return;

      setState(() => _booking = false);
      context.push(
        '/email-verification',
        extra: {
          'email': guestEmail,
          'verificationType': 'reservation',
          'verificationId': verificationId,
        },
      );
      return;
    } catch (e) {
      debugPrint('Booking completely failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: AppColors.statusCancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _booking = false);
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));
    final authState = ref.watch(authStateProvider);

    return roomAsync.when(
      data: (room) {
        if (room == null) {
          return const Scaffold(body: Center(child: Text('Room not found')));
        }
        return _buildRoomDetail(context, room, authState);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) =>
          const Scaffold(body: Center(child: Text('Error loading room'))),
    );
  }

  Widget _buildRoomDetail(
    BuildContext context,
    Room room,
    AuthState authState,
  ) {
    final nights = _checkOut.difference(_checkIn).inDays;
    final totalAmount = room.price * nights;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.darkNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (room.imagePath != null)
                    CachedNetworkImage(
                      imageUrl: room.imagePath!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: Colors.grey[300]),
                      errorWidget: (_, _, _) =>
                          Container(color: AppColors.darkNavy),
                    )
                  else
                    Container(color: AppColors.darkNavy),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            room.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          room.roomNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Up to ${room.capacity} guests',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        'MUR ${NumberFormat('#,###').format(room.price.toInt())}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'per night',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (room.description != null) ...[
                    Text(
                      room.description!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities
                        .map(
                          (amenity) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              amenity,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Booking Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker('Check-in', _checkIn, () => _pickDate(true)),
                  const SizedBox(height: 10),
                  _buildDatePicker(
                    'Check-out',
                    _checkOut,
                    () => _pickDate(false),
                  ),
                  const SizedBox(height: 10),
                  _buildGuestCounter(
                    'Adults',
                    _adults,
                    1,
                    10,
                    (v) => setState(() => _adults = v),
                  ),
                  const SizedBox(height: 10),
                  _buildGuestCounter(
                    'Children',
                    _children,
                    0,
                    10,
                    (v) => setState(() => _children = v),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkNavy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.darkNavy.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total ($nights nights)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'MUR ${NumberFormat('#,###').format(totalAmount.toInt())}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _booking
                          ? null
                          : () {
                              if (!authState.isAuthenticated) {
                                showAuthSheet(
                                  context,
                                  title: 'Sign in to Book',
                                  message:
                                      'Please sign in or create an account to make a reservation.',
                                );
                                return;
                              }
                              final guest = authState.guest;
                              if (guest == null) return;
                              _handleBooking(room, guest.id, guest.email);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _booking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Book This Room',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (authState.isAuthenticated) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'A 6-digit verification code will be sent to your email',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.darkNavy, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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

  Widget _buildGuestCounter(
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
          Icon(
            label == 'Adults' ? Icons.person : Icons.child_care,
            color: AppColors.darkNavy,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
