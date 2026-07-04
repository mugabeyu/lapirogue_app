import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_provider.dart';
import '../../data/providers/reservation_provider.dart';
import '../widgets/auth_sheet.dart';
import '../widgets/lock_overlay.dart';

class ReservationGate extends ConsumerWidget {
  final Widget child;
  final bool requiresCheckIn;
  final String lockedTitle;
  final String lockedMessage;
  final String checkInLockedTitle;
  final String checkInLockedMessage;

  const ReservationGate({
    super.key,
    required this.child,
    this.requiresCheckIn = true,
    this.lockedTitle = 'Feature Locked',
    this.lockedMessage = 'Please make a reservation to unlock this feature.',
    this.checkInLockedTitle = 'Available After Check-In',
    this.checkInLockedMessage =
        'This feature will automatically unlock after you check in at the hotel.',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);

    if (!authState.isAuthenticated) {
      return GestureDetector(
        onTap: () => showAuthSheet(context),
        child: Stack(
          children: [
            child,
            AbsorbPointer(
              child: LockOverlay(
                title: 'Sign In Required',
                message: 'You need an account to access this feature.',
              ),
            ),
          ],
        ),
      );
    }

    if (!reservationState.hasActiveReservation) {
      return Stack(
        children: [
          child,
          LockOverlay(
            title: 'No Reservation',
            message:
                'You currently have no reservation.\nBook a room to unlock hotel services.',
            actionLabel: 'Book a Room',
            onAction: () => context.push('/rooms'),
          ),
        ],
      );
    }

    if (reservationState.isReserved && !requiresCheckIn) {
      return child;
    }

    if (reservationState.isReserved && requiresCheckIn) {
      return Stack(
        children: [
          child,
          AbsorbPointer(
            child: LockOverlay(
              title: checkInLockedTitle,
              message: checkInLockedMessage,
            ),
          ),
        ],
      );
    }

    return child;
  }
}
