# La Pirogue Hotel — Flutter App Documentation

## Architecture Overview

```
Layer         | Tech
------------- | -----
Presentation  | StatefulWidget / StatelessWidget screens
Business      | Singleton Service classes (direct Supabase queries)
Data          | Supabase (Postgres REST API via supabase_flutter)
State Mgmt    | setState() only — no Provider / Bloc / Riverpod
Models        | Immutable Dart classes with fromJson / toJson
```

The app uses **no state management library** — every screen calls services directly and uses `setState` to re-render. Services are **Singletons** that wrap `Supabase.instance.client` calls.

---

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Colors, ThemeData
│   ├── models/                        # 15 data models
│   │   ├── models.dart                # barrel export
│   │   ├── guest.dart
│   │   ├── room.dart
│   │   ├── reservation.dart
│   │   └── ... (15 total)
│   └── services/                      # 10 service classes
│       ├── services.dart              # barrel export
│       ├── supabase_service.dart      # core auth + guest queries
│       ├── session_service.dart
│       ├── guest_service.dart
│       ├── activity_service.dart      # + EcoPointsService
│       ├── content_service.dart
│       ├── message_service.dart
│       ├── notification_service.dart
│       ├── schedule_service.dart
│       ├── food_service.dart
│       ├── payment_service.dart
│       └── storage_service.dart       # file uploads
└── features/
    ├── auth/screens/
    │   ├── session_controller.dart    # auth gate
    │   ├── login_screen.dart
    │   ├── guest_login_screen.dart
    │   ├── forgot_password_screen.dart
    │   └── change_password_screen.dart
    ├── main/screens/
    │   └── main_shell_screen.dart     # bottom nav shell
    ├── explore/screens/
    │   └── explore_screen.dart        # home menu grid
    ├── dashboard/screens/
    │   ├── dashboard_screen.dart
    │   └── widgets/dashboard_card.dart
    ├── activities/screens/
    │   └── activities_screen.dart
    ├── food/screens/
    │   └── food_beverage_screen.dart
    ├── messages/screens/
    │   └── messages_screen.dart
    ├── schedule/screens/
    │   └── daily_schedule_screen.dart
    ├── notifications/screens/
    │   └── notifications_screen.dart
    ├── settings/screens/
    │   └── settings_screen.dart
    ├── hotel_info/screens/
    │   └── hotel_info_screen.dart
    ├── sustainability/screens/
    │   ├── sustainability_screen.dart
    │   └── leaderboard_screen.dart
    ├── payments/screens/
    │   └── payments_screen.dart
    └── feedback/screens/
        └── feedback_screen.dart
```

---

## 1. Entry Point (`main.dart`)

Initialises Supabase from `.env`, applies system UI styling, and launches `LapirogueHotelApp` which routes to `SessionController`.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  SystemChrome.setSystemUIOverlayStyle(/* ... */);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const LapirogueHotelApp());
}

class LapirogueHotelApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SessionController(),
    );
  }
}
```

---

## 2. Auth Flow

### Session Controller — Auth Gate (`session_controller.dart`)

Checks for an existing Supabase session on startup and listens for auth state changes. Routes to `LoginScreen` (unauthenticated) or `MainShellScreen` (authenticated).

```dart
class _SessionControllerState extends State<SessionController> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  void initState() {
    _checkAuthState();
    _listenToAuthChanges();
  }

  void _checkAuthState() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() { _isAuthenticated = session != null; _isLoading = false; });
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() { _isAuthenticated = data.session != null; _isLoading = false; });
    });
  }

  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_isAuthenticated) return const LoginScreen();
    return const MainShellScreen();
  }
}
```

### Login Screen (`login_screen.dart`)

Email/password form with error handling. On success, navigates to `MainShellScreen` via `pushReplacement`.

```dart
Future<void> _signIn() async {
  final response = await SupabaseService.signInWithPassword(
    email: email, password: password,
  );
  if (response.user != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }
}
```

---

## 3. Supabase Service — Core Backend Access (`supabase_service.dart`)

Singleton that exposes static shortcuts for auth and guest queries. All other services follow this same pattern.

```dart
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseQueryBuilder from(String table) => client.from(table);

  static Future<AuthResponse> signInWithPassword({
    required String email, required String password,
  }) => auth.signInWithPassword(email: email, password: password);

  /// Eagerly loads guest with nested reservations + rooms
  static Future<Map<String, dynamic>?> getGuestByAuthId(String authId) async {
    final response = await client
        .from('guests')
        .select('*, reservations(*, rooms(*))')
        .eq('auth_id', authId)
        .maybeSingle();
    return response;
  }

  /// RPC call that bypasses RLS for anonymous booking lookup
  static Future<Map<String, dynamic>?> lookupGuestByBooking({
    required String reservationId, required String lastName,
  }) async {
    final response = await client.rpc('lookup_guest_by_booking', params: {
      'p_reservation_id': reservationId,
      'p_last_name': lastName,
    });
    return response as Map<String, dynamic>?;
  }
}
```

---

## 4. Theme System (`app_theme.dart`)

Centralised colours and a full `ThemeData` using Material 3.

```dart
class AppTheme {
  static const Color primary = Color(0xFF14567D);        // Luxury teal
  static const Color secondary = Color(0xFFD4A574);      // Warm gold/sand
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color accentRed = Color(0xFFC62828);
  static const Color accentOrange = Color(0xFFE65100);
  static const Color accentPurple = Color(0xFF6A1B9A);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 56),
      ),
    ),
    // ... AppBar, BottomNavigationBar, Card, InputDecoration, etc.
  );
}
```

---

## 5. Data Models Pattern

Every model follows this exact pattern — immutable class, `const` constructor, `factory fromJson`, `toJson`.

```dart
class Guest {
  final String id;
  final String? authId;
  final String firstName;
  final String lastName;
  final String email;
  final List<Reservation>? reservations;

  String get fullName => '$firstName $lastName';

  const Guest({
    required this.id, this.authId, required this.firstName,
    required this.lastName, required this.email, this.reservations,
  });

  factory Guest.fromJson(Map<String, dynamic> json) => Guest(
    id: json['id']?.toString() ?? '',
    authId: json['auth_id']?.toString(),
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    email: json['email'] ?? '',
    reservations: (json['reservations'] as List?)
        ?.map((e) => Reservation.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => { /* ... */ };
}
```

---

## 6. Navigation — Bottom Tab Shell (`main_shell_screen.dart`)

`IndexedStack` preserves state across 4 tabs. All screens use `Navigator.push` for sub-navigation.

```dart
class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    ExploreScreen(),        // Home menu grid
    DailyScheduleScreen(),  // Daily itinerary
    MessagesScreen(),       // Chat with staff
    SettingsScreen(),       // Profile / sign out
  ];

  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'My Stay'),
        ],
      ),
    );
  }
}
```

---

## 7. Explore — Home Menu Grid (`explore_screen.dart`)

A 2-column grid of 7 feature cards. Each navigates to its respective screen. Data-driven via a private `_ExploreItem` list.

```dart
static const List<_ExploreItem> _items = [
  _ExploreItem(icon: Icons.explore,        label: 'Activities & Tours',  color: AppTheme.primary),
  _ExploreItem(icon: Icons.restaurant,     label: 'Food & Beverage',     color: AppTheme.accentOrange),
  _ExploreItem(icon: Icons.calendar_today, label: 'Daily Schedule',      color: AppTheme.secondary),
  _ExploreItem(icon: Icons.info_outline,   label: 'Hotel Information',   color: AppTheme.primaryLight),
  _ExploreItem(icon: Icons.eco,            label: 'Sustainability',      color: AppTheme.accentGreen),
  _ExploreItem(icon: Icons.notifications,  label: 'Notifications',       color: AppTheme.accentPurple),
  _ExploreItem(icon: Icons.feedback,       label: 'Feedback',            color: AppTheme.textSecondary),
];

void _navigate(BuildContext context, String label) {
  switch (label) {
    case 'Activities & Tours': Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
    case 'Food & Beverage':    Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodBeverageScreen()));
    // ...
  }
}
```

---

## 8. Dashboard — Parallel Data Loading (`dashboard_screen.dart`)

The dashboard loads 5 data sources in parallel via `Future.wait`, then renders a `CustomScrollView` with `SliverAppBar`.

```dart
Future<void> _loadData() async {
  _guest = await GuestService().getCurrentGuest();
  if (_guest == null) return;

  final guestId = _guest!.id;
  final results = await Future.wait([
    GuestService().getUnreadNotificationsCount(guestId),
    GuestService().getUnreadMessagesCount(guestId),
    EcoPointsService().getEcoPointsBalance(guestId),
    ScheduleService().getTodaysSchedule(guestId),
    MessageService().getMessages(guestId),
  ]);

  setState(() {
    _unreadNotifications = results[0] as int;
    _unreadMessages = results[1] as int;
    _ecoPoints = results[2] as int;
    _todaySchedule = (results[3] as List).take(3).toList();
    _latestMessages = (results[4] as List).take(3).toList();
    if (_guest!.reservations?.isNotEmpty == true) {
      final r = _guest!.reservations![0];
      _roomNumber = r.room?.roomNumber ?? '--';
      _checkInDate = r.checkIn.toIso8601String().split('T').first;
    }
    _isLoading = false;
  });
}
```

---

## 9. Chat — Messages Screen (`messages_screen.dart`)

Guest messages appear right-aligned in teal bubbles, staff messages left-aligned in white. Avatars group consecutive messages from the same sender.

```dart
Widget _buildMessageBubble({
  required Message message, required bool isGuest, required bool showAvatar,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isGuest ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isGuest && showAvatar) /* staff avatar - support_agent icon */,
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isGuest ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isGuest ? 16 : 4),
                bottomRight: Radius.circular(isGuest ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.content),
                Text(DateFormat('HH:mm').format(createdAt)),
              ],
            ),
          ),
        ),
        if (isGuest && showAvatar) /* guest avatar - person icon */,
      ],
    ),
  );
}
```

---

## 10. Eco Points — Multi-Step Participation (`activity_service.dart`)

When a guest participates in an eco action, the service performs 3 database operations: inserts a transaction record, logs the action, and calls an RPC to update the balance.

```dart
Future<bool> participateInEcoAction({
  required String guestId, required String actionId,
}) async {
  // 1. Fetch the action to get point value
  final action = await _client.from('eco_actions')
      .select('title, points, description')
      .eq('id', actionId).maybeSingle();

  final actionPoints = action?['points'] ?? 0;

  // 2. Insert points transaction
  await _client.from('eco_points_tx').insert({
    'guest_id': guestId, 'tx_type': 'EARN',
    'points': actionPoints, 'status': 'COMPLETED',
  });

  // 3. Insert tracking record
  await _client.from('guest_eco_actions').insert({
    'guest_id': guestId, 'eco_action_id': actionId,
    'earned_points': actionPoints,
  });

  // 4. RPC updates balance + recalculates tier
  await _client.rpc('increment_eco_points', params: {
    'p_guest_id': guestId, 'p_points': actionPoints,
  });

  return true;
}
```

---

## 11. Profile Photo Upload (`settings_screen.dart`)

Uses `ImagePicker`, uploads to Supabase Storage, then updates the guest record.

```dart
Future<void> _pickAndUploadPhoto() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (pickedFile == null) return;

  final file = File(pickedFile.path);
  final imageUrl = await StorageService().uploadGuestPhoto(_guest!.id, file);
  if (imageUrl != null) {
    await GuestService().updateProfileImagePath(_guest!.id, imageUrl);
    setState(() => _loadGuestData());
  }
}
```

---

## 12. Anonymous Booking Lookup (`supabase_service.dart`)

Guests without an account can look up their booking by reservation ID + last name via a Supabase RPC (SECURITY DEFINER, bypasses RLS).

```dart
static Future<Map<String, dynamic>?> lookupGuestByBooking({
  required String reservationId, required String lastName,
}) async {
  final response = await client.rpc('lookup_guest_by_booking', params: {
    'p_reservation_id': reservationId,
    'p_last_name': lastName,
  });
  return response as Map<String, dynamic>?;
}

/// Then links the anonymous Supabase auth user to the guest record:
static Future<bool> linkGuestAuth({
  required String guestId, required String authId,
}) async {
  final response = await client.rpc('link_guest_auth', params: {
    'p_guest_id': guestId,
    'p_auth_id': authId,
  });
  return response == true;
}
```

---

## Summary of Key Patterns

| Pattern | Usage |
|---|---|
| **Singleton Services** | All 10 services use `_instance` + `_internal()` pattern |
| **setState State Mgmt** | No external state management library used |
| **Immutable Models** | All 15 models have `fromJson` / `toJson` |
| **Supabase REST** | Direct `client.from('table').select(...)` — no repository layer |
| **Future.wait** | Dashboard loads 5 data sources in parallel |
| **IndexedStack** | Bottom nav preserves tab state |
| **Navigator.push** | All sub-page navigation via `MaterialPageRoute` |
| **RPC Functions** | `lookup_guest_by_booking`, `link_guest_auth`, `increment_eco_points` |
| **Material 3** | `useMaterial3: true` in theme |
