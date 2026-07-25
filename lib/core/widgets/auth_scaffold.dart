import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Shared frame for the account screens (forgot password, verification code,
/// set a new password).
///
/// These steps used to sit on a plain white page, which made a resort app
/// feel like a form. The hotel photograph runs behind a content sheet so the
/// guest still knows where they are, while the sheet keeps the text on a
/// solid surface — a scrim alone is not reliable contrast over a photo whose
/// bright areas vary.
class AuthScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The photo keeps a fixed share of the screen so the sheet lands in the
    // same place on a small phone and a tall one.
    final imageHeight = media.size.height * 0.32;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBack && context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                onPressed: () => context.pop(),
                tooltip: 'Back',
              )
            : null,
        title: Text(
          title,
          style: AppTypography.cardTitle.copyWith(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: imageHeight + AppTheme.radiusLg,
            width: double.infinity,
            child: Image.asset(
              'assets/images/home.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              // If the asset ever fails to decode the screen must still be
              // usable, so fall back to a flat brand surface.
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.primaryDark),
            ),
          ),

          // Darkens the top of the photo so the white title and back arrow
          // stay legible over the bright sky in the image.
          SizedBox(
            height: imageHeight + AppTheme.radiusLg,
            width: double.infinity,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8C000000), Color(0x1A000000)],
                  stops: [0, 0.65],
                ),
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: imageHeight),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.screenPadding,
                        AppTheme.space8,
                        AppTheme.screenPadding,
                        AppTheme.space8,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
