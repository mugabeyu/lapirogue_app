import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/auth_sheet.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../data/providers/hotel_provider.dart';
import '../../../core/models/room.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/session_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late String _greeting;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final q = query.trim().toLowerCase();
      final response = await Supabase.instance.client
          .from('rooms')
          .select('*')
          .or('room_number.ilike.%$q%,type.ilike.%$q%,description.ilike.%$q%');
      setState(() => _searchResults = response);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SearchResultsSheet(results: _searchResults),
        );
      }
    } catch (_) {}
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);
    final featuredRoomsAsync = ref.watch(featuredRoomsProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeroSliver(authState, reservationState),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Featured Rooms',
              actionLabel: 'View All',
              onAction: () => context.push('/rooms'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: featuredRoomsAsync.when(
                data: (rooms) => _buildRoomCarousel(rooms, authState),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Unable to load rooms')),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SectionHeader(title: 'Hotel Facilities')),
          SliverToBoxAdapter(child: _buildFacilitiesGrid()),
          SliverToBoxAdapter(child: SectionHeader(title: 'Activities & Tours')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: activitiesAsync.when(
                data: (activities) => activities.isEmpty
                    ? const Center(child: Text('No activities available'))
                    : _buildActivitiesCarousel(
                        activities,
                        authState,
                        reservationState,
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Unable to load activities')),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SectionHeader(title: 'Food & Beverages')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: menuItemsAsync.when(
                data: (items) => items.isEmpty
                    ? const Center(child: Text('No menu items available'))
                    : _buildFoodCarousel(items),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Unable to load menu')),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeroSliver(
    AuthState authState,
    ReservationState reservationState,
  ) {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: false,
      floating: false,
      backgroundColor: AppColors.oceanBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/home.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.oceanBlue),
                ),
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/lapirogue_logo.jpg',
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
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
                  if (authState.isAuthenticated)
                    Text(
                      '$_greeting, ${authState.guest?.firstName ?? 'Guest'}!',
                      style: AppTypography.sectionHeader.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      '$_greeting!',
                      style: AppTypography.sectionHeader.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to La Pirogue Mauritius',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (reservationState.isCheckedIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusConfirmed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.statusConfirmed.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.statusConfirmed,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Enjoying Your Stay',
                            style: TextStyle(
                              color: AppColors.statusConfirmed,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (reservationState.isReserved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusPending.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.statusPending.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppColors.statusPending,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Reservation Confirmed',
                            style: TextStyle(
                              color: AppColors.statusPending,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: authState.isAuthenticated
                    ? () => context.push('/notifications')
                    : () => showAuthSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: 'Search rooms, amenities...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCarousel(List<Room> rooms, AuthState authState) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return GestureDetector(
          onTap: () => context.push('/rooms/${room.id}'),
          child: Container(
            width: 260,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: room.imagePath ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: Colors.grey[200]),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.lightGray,
                          child: const Icon(
                            Icons.image,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                room.type,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.goldAccent,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'MUR ${NumberFormat('#,###').format(room.price.toInt())}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          room.roomNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Up to ${room.capacity} guests',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacilitiesGrid() {
    final facilities = [
      {'icon': Icons.pool, 'label': 'Swimming Pool'},
      {'icon': Icons.beach_access, 'label': 'Beach'},
      {'icon': Icons.spa, 'label': 'Spa'},
      {'icon': Icons.restaurant, 'label': 'Restaurant'},
      {'icon': Icons.fitness_center, 'label': 'Gym'},
      {'icon': Icons.child_care, 'label': 'Kids Club'},
      {'icon': Icons.meeting_room, 'label': 'Conference'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: facilities.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final f = facilities[index];
            return Container(
              width: 72,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    color: AppColors.oceanBlue,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f['label'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivitiesCarousel(
    List<Activity> activities,
    AuthState authState,
    ReservationState reservationState,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return GestureDetector(
          onTap: () => _handleActivityClick(
            activity,
            authState,
            reservationState,
            context,
          ),
          child: Container(
            width: 180,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.oceanBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_bike,
                    color: AppColors.oceanBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'MUR ${NumberFormat('#,###').format(activity.price.toInt())}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.oceanBlue,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${activity.duration}min',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodCarousel(List<MenuItem> items) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: 170,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                  image: item.imagePath != null
                      ? DecorationImage(
                          image: NetworkImage(item.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imagePath == null
                    ? const Icon(
                        Icons.restaurant,
                        color: AppColors.textTertiary,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.description!,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Text(
                    'MUR ${NumberFormat('#,###').format(item.price.toInt())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.oceanBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.preparationMinutes}min',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.oceanBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleActivityClick(
    Activity activity,
    AuthState authState,
    ReservationState reservationState,
    BuildContext context,
  ) async {
    if (!authState.isAuthenticated) {
      showAuthSheet(context);
      return;
    }
    if (!reservationState.hasActiveReservation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please make a reservation first')),
      );
      return;
    }
    try {
      final guest = await SessionService.getCurrentGuest();
      if (guest == null) return;
      final guestId = guest['id'].toString();
      final activeReservation = reservationState.activeReservation;
      final now = DateTime.now();
      final bookingDate =
          activeReservation != null && activeReservation.checkIn.isAfter(now)
          ? activeReservation.checkIn
          : now;
      final baseUrl = await AuthService().baseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/activities/book'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'activityId': activity.id,
          'guestId': guestId,
          'date': bookingDate.toIso8601String().split('T').first,
          'timeSlot': activity.defaultTime ?? '09:00',
          'participants': 1,
          'status': 'CONFIRMED',
          'origin': 'MOBILE_APP',
        }),
      );

      if (response.statusCode >= 400) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(payload['error'] ?? 'Unable to book activity');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${activity.name} booked! Check your schedule.'),
            backgroundColor: AppColors.statusConfirmed,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.statusCancelled,
          ),
        );
      }
    }
  }
}

class _SearchResultsSheet extends StatelessWidget {
  final List<dynamic> results;
  const _SearchResultsSheet({required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${results.length} room(s) found',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final room = results[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.network(
                        room['image_path'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.lightGray,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    room['room_number'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${room['type']} - MUR ${NumberFormat('#,###').format((room['price'] ?? 0).toInt())}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/rooms/${room['id']}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
