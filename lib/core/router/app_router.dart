import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/mystay/screens/my_stay_screen.dart';
import '../../features/reservations/screens/reservations_screen.dart';
import '../../features/reservations/screens/reservation_detail_screen.dart';
import '../../features/reservations/screens/booking_confirmation_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/rooms/screens/room_detail_screen.dart';
import '../../features/rooms/screens/rooms_list_screen.dart';
import '../../features/dining/screens/dining_screen.dart';
import '../../features/activities/screens/activities_screen.dart';
import '../../features/spa/screens/spa_screen.dart';
import '../../features/room_service/screens/room_service_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/hotel_info/screens/hotel_info_screen.dart';
import '../../features/schedule/screens/daily_schedule_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/profile/screens/update_password_screen.dart';
import '../../features/profile/screens/eco_points_screen.dart';
import '../../features/profile/screens/settings_screen.dart';

import '../../data/providers/auth_provider.dart';
import '../theme/app_colors.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.needsOnboarding != next.needsOnboarding ||
          previous?.isRecoveringPassword != next.isRecoveringPassword) {
        notifyListeners();
      }
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // IMPORTANT: this provider must stay stable across auth state changes.
  // It intentionally does NOT `ref.watch(authStateProvider)` — doing so
  // would recreate (dispose + rebuild) the GoRouter, including its
  // GoRouteInformationProvider, every time `isLoading` toggles (i.e. on
  // every login/signUp call). Any in-flight `context.push`/`context.go`
  // issued right after such a call would then crash with
  // "A GoRouteInformationProvider was used after being disposed."
  // Instead, auth state is read fresh inside `redirect` via `ref.read`,
  // and `refreshListenable` tells GoRouter to re-run `redirect` when it
  // actually matters (auth/onboarding status changes) without tearing
  // down the router itself.
  final refreshNotifier = _AuthRefreshNotifier(ref);

  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password' ||
          state.matchedLocation == '/email-verification';

      // Verifying a recovery code hands back a real Supabase session before a
      // new password exists. Until that password is set the guest is not
      // signed in, so pin them to the reset screen rather than letting the
      // session carry them into the app.
      if (authState.isRecoveringPassword) {
        return state.matchedLocation == '/reset-password'
            ? null
            : '/reset-password';
      }

      if (!isLoggedIn && isAuthRoute) return null;
      if (isLoggedIn && isAuthRoute) return '/';

      if (isLoggedIn &&
          authState.needsOnboarding &&
          state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      if (isLoggedIn &&
          !authState.needsOnboarding &&
          state.matchedLocation == '/onboarding') {
        return '/';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/rooms',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RoomsListScreen()),
          ),
          GoRoute(
            path: '/reservations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReservationsScreen()),
          ),
          GoRoute(
            path: '/dining',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DiningScreen()),
          ),
          GoRoute(
            path: '/my-stay',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyStayScreen()),
          ),
          GoRoute(
            path: '/daily-schedule',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DailyScheduleScreen()),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MessagesScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/reservations/:id',

        builder: (context, state) =>
            ReservationDetailScreen(reservationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-confirmation',
        
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingConfirmationScreen(
            reservationId: extra?['reservationId'] as String? ?? '',
            checkIn: extra?['checkIn'] as String? ?? '',
            checkOut: extra?['checkOut'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/booking',
        
        builder: (context, state) {
          final item = state.extra as BookingItem?;
          if (item == null) {
            return const Scaffold(body: Center(child: Text('No booking data')));
          }
          return BookingScreen(item: item);
        },
      ),
      GoRoute(
        path: '/login',
        
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EmailVerificationScreen(
            email: extra?['email'] as String? ?? '',
            verificationType: extra?['verificationType'] as String? ?? 'signup',
            verificationId: extra?['verificationId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/forgot-password',

        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',

        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? state.uri.queryParameters['email'];
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/rooms/:id',

        builder: (context, state) =>
            RoomDetailScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders',
        
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/activities',
        
        builder: (context, state) => const ActivitiesScreen(),
      ),
      GoRoute(
        path: '/spa',
        
        builder: (context, state) => const SpaScreen(),
      ),
      GoRoute(
        path: '/room-service',
        
        builder: (context, state) => const RoomServiceScreen(),
      ),
      GoRoute(
        path: '/notifications',
        
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/feedback',
        
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/hotel-info',
        
        builder: (context, state) => const HotelInfoScreen(),
      ),
      GoRoute(
        path: '/payments',
        
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/update-password',

        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/eco-points',

        builder: (context, state) => const EcoPointsScreen(),
      ),
      GoRoute(
        path: '/settings',

        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });
  return router;
});

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location == '/daily-schedule') currentIndex = 1;
    if (location == '/messages') currentIndex = 2;
    if (location == '/profile') currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.lightGray2, width: 1)),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                  case 1:
                    context.go('/daily-schedule');
                  case 2:
                    context.go('/messages');
                  case 3:
                    context.go('/profile');
                }
              },
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textTertiary,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_note_outlined),
                  activeIcon: Icon(Icons.event_note),
                  label: 'Schedule',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
