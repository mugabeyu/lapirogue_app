import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Shared building blocks for the guest app.
///
/// Screens used to hand-roll their own `Container` + `BoxDecoration` +
/// `TextStyle` for every card, heading and pill, which is why no two screens
/// agreed on a radius, a shadow or a font size. Compose from these instead.

/// Standard content surface: white, hairline border, large radius.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? background;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppTheme.space5),
      child: child,
    );

    return Material(
      color: background ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Section heading with an optional trailing action.
///
/// The action is a real `TextButton` rather than a tappable `Text`, so it
/// gets a proper hit target and press feedback.
class SectionHeading extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.sectionTitle)),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space2,
                  vertical: AppTheme.space1,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Small status badge. Tone carries the meaning, so the label never has to
/// be colour-only — it is always readable text as well.
enum StatusTone { success, warning, danger, info, neutral }

class StatusPill extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusPill({super.key, required this.label, this.tone = StatusTone.neutral});

  Color get _foreground => switch (tone) {
        StatusTone.success => AppColors.success,
        StatusTone.warning => AppColors.warning,
        StatusTone.danger => AppColors.danger,
        StatusTone.info => AppColors.info,
        StatusTone.neutral => AppColors.neutralStatus,
      };

  Color get _background => switch (tone) {
        StatusTone.success => AppColors.successSoft,
        StatusTone.warning => AppColors.warningSoft,
        StatusTone.danger => AppColors.dangerSoft,
        StatusTone.info => AppColors.infoSoft,
        StatusTone.neutral => AppColors.neutralStatusSoft,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(
          color: _foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Label above a value, for the detail lists inside cards.
class DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;

  const DetailRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: AppTheme.space3),
          ],
          Text(label, style: AppTypography.body),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen "nothing here yet" state with an optional call to action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceMuted,
              ),
              child: Icon(icon, size: 38, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppTheme.space6),
            Text(title, style: AppTypography.heading, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space2),
            Text(message, style: AppTypography.body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.space6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One figure in a row of summary figures.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space3,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              value,
              style: AppTypography.priceSmall.copyWith(color: valueColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Centred spinner sized for an inline section rather than a whole page.
class InlineLoader extends StatelessWidget {
  final double height;
  const InlineLoader({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}
