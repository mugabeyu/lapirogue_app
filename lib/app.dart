import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/providers/auth_provider.dart';

class LapirogueHotelApp extends ConsumerStatefulWidget {
  const LapirogueHotelApp({super.key});

  @override
  ConsumerState<LapirogueHotelApp> createState() => _LapirogueHotelAppState();
}

class _LapirogueHotelAppState extends ConsumerState<LapirogueHotelApp> {
  // Tracks only the *initial* app bootstrap (session restore on launch).
  // Once this flips to true it stays true for the app's lifetime, so later
  // `isLoading` toggles (login, signUp, logout, refreshGuest, ...) never
  // again swap out the router-based MaterialApp for the plain loading one.
  // Doing that mid-action was what tore down the GoRouter (and its
  // GoRouteInformationProvider) while a screen was mid-navigation, causing
  // "A GoRouteInformationProvider was used after being disposed." crashes.
  bool _bootstrapped = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (!_bootstrapped) {
      if (!authState.isLoading) {
        _bootstrapped = true;
      } else {
        return MaterialApp(
          title: 'La Pirogue Hotel',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          ),
        );
      }
    }

    return MaterialApp.router(
      title: 'La Pirogue Hotel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
