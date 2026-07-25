import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-screen success/error confirmation shown *before* the app navigates
/// away from an action (OTP verified, password reset, etc.), instead of a
/// SnackBar that flashes past while the next screen is already loading.
/// Await this, then perform the navigation once it resolves.
Future<void> showResultOverlay(
  BuildContext context, {
  required bool success,
  required String title,
  String? message,
  Duration autoContinueAfter = const Duration(milliseconds: 1400),
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.background,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => _ResultOverlayBody(
      success: success,
      title: title,
      message: message,
      autoContinueAfter: autoContinueAfter,
    ),
    transitionBuilder: (ctx, animation, _, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _ResultOverlayBody extends StatefulWidget {
  final bool success;
  final String title;
  final String? message;
  final Duration autoContinueAfter;

  const _ResultOverlayBody({
    required this.success,
    required this.title,
    this.message,
    required this.autoContinueAfter,
  });

  @override
  State<_ResultOverlayBody> createState() => _ResultOverlayBodyState();
}

class _ResultOverlayBodyState extends State<_ResultOverlayBody> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.autoContinueAfter, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? AppColors.statusConfirmed : AppColors.statusCancelled;
    final bgColor = widget.success ? AppColors.statusConfirmedBg : AppColors.statusCancelledBg;
    final icon = widget.success ? Icons.check_circle : Icons.error;

    return Material(
      color: AppColors.background,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                    child: Icon(icon, size: 56, color: color),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
