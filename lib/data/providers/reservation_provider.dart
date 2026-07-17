import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/reservation.dart';
import '../../core/services/session_service.dart';
import 'auth_provider.dart';

enum ReservationStatusType {
  none,
  pending,
  reserved,
  checkedIn,
  checkedOut,
  cancelled,
}

class ReservationState {
  final Reservation? activeReservation;
  final List<Reservation> reservations;
  final ReservationStatusType status;
  final bool isLoading;
  final String? error;

  const ReservationState({
    this.activeReservation,
    this.reservations = const [],
    this.status = ReservationStatusType.none,
    this.isLoading = false,
    this.error,
  });

  bool get hasActiveReservation => activeReservation != null;
  bool get isCheckedIn => status == ReservationStatusType.checkedIn;
  bool get isReserved => status == ReservationStatusType.reserved;
  bool get isPending => status == ReservationStatusType.pending;
  bool get canUseServices => status == ReservationStatusType.checkedIn;

  ReservationState copyWith({
    Reservation? activeReservation,
    List<Reservation>? reservations,
    ReservationStatusType? status,
    bool? isLoading,
    String? error,
  }) {
    return ReservationState(
      activeReservation: activeReservation ?? this.activeReservation,
      reservations: reservations ?? this.reservations,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReservationNotifier extends StateNotifier<ReservationState> {
  ReservationNotifier() : super(const ReservationState());

  Reservation? _pickActiveReservation(List<Reservation> reservations) {
    for (final reservation in reservations) {
      if (reservation.status == 'CHECKED_IN') {
        return reservation;
      }
    }

    for (final reservation in reservations) {
      if (reservation.status == 'RESERVED' ||
          reservation.status == 'CONFIRMED') {
        return reservation;
      }
    }

    return null;
  }

  Future<void> loadReservations(String guestId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await Supabase.instance.client
          .from('reservations')
          .select('*, rooms(*)')
          .eq('guest_id', guestId)
          .order('created_at', ascending: false);

      final reservations = (response as List)
          .map((e) => Reservation.fromJson(e))
          .toList();

      ReservationStatusType statusType = ReservationStatusType.none;
      final active = _pickActiveReservation(reservations);

      if (active != null) {
        statusType = switch (active.status) {
          'CHECKED_IN' => ReservationStatusType.checkedIn,
          'RESERVED' => ReservationStatusType.reserved,
          'CONFIRMED' => ReservationStatusType.reserved,
          'CHECKED_OUT' => ReservationStatusType.checkedOut,
          'CANCELLED' || 'NO_SHOW' => ReservationStatusType.cancelled,
          _ => ReservationStatusType.reserved,
        };
      }

      state = ReservationState(
        activeReservation: active,
        reservations: reservations,
        status: statusType,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'We couldn\'t load your reservations. Please try again.');
    }
  }

  void clear() {
    state = const ReservationState();
  }

  Future<void> refresh() async {
    final guest = await SessionService.getCurrentGuest();
    if (guest != null) {
      await loadReservations(guest['id'].toString());
    } else {
      clear();
    }
  }
}

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, ReservationState>((ref) {
      final notifier = ReservationNotifier();

      ref.listen(authStateProvider, (previous, next) {
        final guestId = next.guest?.id;
        if (next.isAuthenticated && guestId != null) {
          notifier.loadReservations(guestId);
        } else if (!next.isAuthenticated) {
          notifier.clear();
        }
      }, fireImmediately: true);

      return notifier;
    });
