import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Guest-facing label/color for a raw backend reservation status.
///
/// Guests can only ever create a reservation (landing as RESERVED) — only
/// hotel staff move it through CONFIRMED / CHECKED_IN / CHECKED_OUT. To the
/// guest, a freshly-made booking hasn't been actioned by staff yet, so
/// RESERVED is shown as "Pending" rather than exposing the internal name.
class ReservationStatusInfo {
  final String label;
  final Color color;
  final Color backgroundColor;

  const ReservationStatusInfo(this.label, this.color, this.backgroundColor);

  factory ReservationStatusInfo.forStatus(String status) {
    switch (status.toUpperCase()) {
      case 'RESERVED':
        return ReservationStatusInfo('Pending', AppColors.statusPending, AppColors.statusPendingBg);
      case 'CONFIRMED':
        return ReservationStatusInfo('Confirmed', AppColors.statusConfirmed, AppColors.statusConfirmedBg);
      case 'CHECKED_IN':
        return ReservationStatusInfo('Checked In', AppColors.statusInfo, AppColors.statusInfoBg);
      case 'CHECKED_OUT':
        return ReservationStatusInfo('Checked Out', AppColors.statusNeutral, AppColors.statusNeutralBg);
      case 'CANCELLED':
        return ReservationStatusInfo('Cancelled', AppColors.statusCancelled, AppColors.statusCancelledBg);
      case 'NO_SHOW':
        return ReservationStatusInfo('No Show', AppColors.statusCancelled, AppColors.statusCancelledBg);
      default:
        return ReservationStatusInfo(status, AppColors.statusNeutral, AppColors.statusNeutralBg);
    }
  }
}
