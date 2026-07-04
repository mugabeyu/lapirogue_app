import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/mystay/screens/my_stay_screen.dart';
import '../../features/reservations/screens/reservations_screen.dart';
import '../../features/reservations/screens/booking_confirmation_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/rooms/screens/room_detail_screen.dart';
import '../../features/rooms/screens/rooms_list_screen.dart';
import '../../features/dining/screens/dining_screen.dart';
import '../../features/activities/screens/activities_screen.dart';
import '../../features/spa/screens/spa_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/room_service/screens/room_service_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/hotel_info/screens/hotel_info_screen.dart';
import '../../features/schedule/screens/daily_schedule_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/profile/screens/payment_methods_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/privacy_screen.dart';
import '../../features/profile/screens/help_screen.dart';
import '../../features/profile/screens/contact_support_screen.dart';

import '../../data/providers/auth_provider.dart';
import '../theme/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  final router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

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
            path: '/my-stay',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MyStayScreen()),
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
        path: '/reservations',
        builder: (context, state) => const ReservationsScreen(),
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
        path: '/rooms',
        
        builder: (context, state) => const RoomsListScreen(),
      ),
      GoRoute(
        path: '/rooms/:id',
        
        builder: (context, state) =>
            RoomDetailScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/dining',
        
        builder: (context, state) => const DiningScreen(),
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
        path: '/gallery',
        
        builder: (context, state) => const GalleryScreen(),
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
        path: '/daily-schedule',
        
        builder: (context, state) => const DailyScheduleScreen(),
      ),
      GoRoute(
        path: '/payments',
        
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/settings',
        
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/help',
        
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/contact-support',
        
        builder: (context, state) => const ContactSupportScreen(),
      ),
    ],
  );

  ref.onDispose(() => router.dispose());
  return router;
});

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location == '/my-stay') currentIndex = 1;
    if (location == '/messages') currentIndex = 2;
    if (location == '/profile') currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                        context.go('/my-stay');
                      case 2:
                        context.go('/messages');
                      case 3:
                        context.go('/profile');
                    }
                  },
                  backgroundColor: AppColors.surfaceLight,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.darkNavy,
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
                      icon: Icon(Icons.villa_outlined),
                      activeIcon: Icon(Icons.villa),
                      label: 'My Stay',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_outlined),
                      activeIcon: Icon(Icons.chat),
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
        ),
      ),
    );
  }
}
