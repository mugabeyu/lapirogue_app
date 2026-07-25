import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPadding,
          AppTheme.space2,
          AppTheme.screenPadding,
          AppTheme.space8,
        ),
        children: [
          const _SectionLabel('Account'),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.lock_outline_rounded,
                label: 'Update password',
                route: '/update-password',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          const _SectionLabel('Feedback'),
          _SettingsGroup(
            children: [
              _SettingsItem(
                icon: Icons.star_outline_rounded,
                label: 'Leave a review',
                route: '/feedback',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space1,
        AppTheme.space4,
        AppTheme.space1,
        AppTheme.space3,
      ),
      child: Text(text.toUpperCase(), style: AppTypography.overline),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push(route),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, size: 19, color: AppColors.primary),
      ),
      title: Text(label, style: AppTypography.bodyMedium),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 22,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space2,
      ),
    );
  }
}
