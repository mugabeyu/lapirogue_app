import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Full-screen success/error confirmation shown *before* the app navigates
/// away from an action (OTP verified, booking made, password changed).
///
/// A SnackBar is the wrong tool for these: it flashes past while the next
/// screen is already pushing in, so the guest never reads it and is left
/// unsure whether anything happened. This holds the screen for a beat,
/// states the outcome plainly, and only then hands back to the caller.
///
/// Await it, then navigate once it resolves.
Future<void> showResultOverlay(
  BuildContext context, {
  required bool success,
  required String title,
  String? message,
  Duration autoContinueAfter = const Duration(milliseconds: 1600),
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.primaryDark,
    transitionDuration: const Duration(milliseconds: 240),
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
          scale: Tween<double>(begin: 0.96, end: 1).animate(
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

class _ResultOverlayBodyState extends State<_ResultOverlayBody>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _ringScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();

    _badgeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.elasticOut),
    );

    // A soft halo that expands and fades once, so the mark reads as a
    // confirmation landing rather than a static icon.
    _ringScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1, curve: Curves.easeOutCubic),
    );

    _timer = Timer(widget.autoContinueAfter, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.success ? AppColors.success : AppColors.danger;
    final soft = widget.success ? AppColors.successSoft : AppColors.dangerSoft;
    final icon = widget.success
        ? Icons.check_rounded
        : Icons.priority_high_rounded;

    return Material(
      color: AppColors.primaryDark,
      child: GestureDetector(
        // Lets an impatient guest skip ahead instead of waiting out the timer.
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/home.jpeg',
              fit: BoxFit.cover,
              // The screen must still be readable if the asset fails to
              // decode, so fall back to the flat brand colour behind it.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),

            // The photo is busy and bright in places; this keeps the badge and
            // the white copy legible wherever they land on it.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xE6062B2B), Color(0xF20A4F52)],
                ),
              ),
            ),

            SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ringScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.6 + _ringScale.value * 0.4,
                              child: Opacity(
                                opacity: (1 - _ringScale.value) * 0.5,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: soft,
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: _badgeScale,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: soft,
                            ),
                            child: Icon(icon, size: 52, color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space6),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    // White copy: this now sits on the darkened hotel photo
                    // rather than the app's white background.
                    style: AppTypography.heading.copyWith(color: Colors.white),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppTheme.space2),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Tap to continue',
                    style: AppTypography.small.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
