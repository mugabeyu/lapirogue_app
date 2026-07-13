import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../data/providers/hotel_provider.dart';
import '../widgets/hero_section.dart';
import '../widgets/booking_card.dart';
import '../widgets/current_stay_card.dart';
import '../widgets/room_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/food_card.dart';
import '../widgets/special_request_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);
    final featuredRoomsAsync = ref.watch(featuredRoomsProvider);
    final activitiesAsync = ref.watch(activitiesProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);

    final hasActive = reservationState.hasActiveReservation;
    final reservation = hasActive ? reservationState.activeReservation : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HeroSection(
              firstName: authState.guest?.firstName,
            ),
          ),
          if (!hasActive)
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: BookingCard(
                  checkIn: _checkIn,
                  checkOut: _checkOut,
                  onCheckInChanged: (d) => setState(() => _checkIn = d),
                  onCheckOutChanged: (d) => setState(() => _checkOut = d),
                  onSearch: () => context.push('/rooms'),
                ),
              ),
            ),
          if (hasActive && reservation != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CurrentStayCard(
                  reservation: reservation,
                  roomNumber: reservation.room?.roomNumber ?? 'Room ${reservation.roomId ?? ''}',
                  roomImage: reservation.room?.imagePath,
                ),
              ),
            ),
SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured Rooms', style: AppTypography.sectionTitle),
                  TextButton(
                    onPressed: () => context.push('/rooms'),
                    child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.goldAccent, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
          featuredRoomsAsync.when(
            data: (rooms) => SliverToBoxAdapter(
              child: SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => RoomCard(room: rooms[index]),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 340,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Activities', style: AppTypography.sectionTitle),
                  TextButton(
                    onPressed: () => context.push('/activities'),
                    child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.goldAccent, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
          activitiesAsync.when(
            data: (activities) => SliverToBoxAdapter(
              child: SizedBox(
                height: 290,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: activities.length > 5 ? 5 : activities.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ActivityCard(activity: activities[index]),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 290,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Food & Drinks', style: AppTypography.sectionTitle),
                  TextButton(
                    onPressed: () => context.push('/dining'),
                    child: const Text('View All', style: TextStyle(fontSize: 13, color: AppColors.goldAccent, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
          menuItemsAsync.when(
            data: (items) => SliverToBoxAdapter(
              child: SizedBox(
                height: 270,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length > 6 ? 6 : items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => FoodCard(item: items[index]),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 270,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: SpecialRequestBanner(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
