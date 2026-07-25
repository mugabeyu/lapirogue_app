import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui.dart';

/// Guest-facing label/color for a raw backend reservation status.
///
/// A booking that has been made is "Reserved" — that is what the guest did and
/// what reception sees, so both apps say the same word. It used to render as
/// "Pending", which read as though the booking had not gone through.
///
/// CONFIRMED is treated as the same thing: it only survives on older rows and
/// is no longer a status staff can set.
class ReservationStatusInfo {
  final String label;
  final Color color;
  final Color backgroundColor;

  const ReservationStatusInfo(this.label, this.color, this.backgroundColor);

  /// Lets a status drive a [StatusPill] without each screen mapping the
  /// colours itself.
  StatusTone get tone {
    if (color == AppColors.success) return StatusTone.success;
    if (color == AppColors.warning) return StatusTone.warning;
    if (color == AppColors.danger) return StatusTone.danger;
    if (color == AppColors.info) return StatusTone.info;
    return StatusTone.neutral;
  }

  factory ReservationStatusInfo.forStatus(String status) {
    switch (status.toUpperCase()) {
      case 'RESERVED':
      case 'CONFIRMED':
        return ReservationStatusInfo('Reserved', AppColors.statusConfirmed, AppColors.statusConfirmedBg);
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
