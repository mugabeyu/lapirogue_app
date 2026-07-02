# La Pirogue Hotel — Mobile App Documentation

**Technology Stack**
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod (StateNotifier + FutureProvider + StreamProvider)
- **Navigation:** GoRouter (declarative, with auth redirects)
- **Backend:** Supabase (PostgreSQL + Auth + Realtime + Storage)
- **Backend API:** Next.js (custom endpoints for reservation OTP flow)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Emails:** Resend (via Next.js backend)
- **Font:** DM Sans (Google Fonts)

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Architecture & Data Flow](#2-architecture--data-flow)
3. [State Management](#3-state-management)
4. [Navigation & Routing](#4-navigation--routing)
5. [Complete Guest Journey](#5-complete-guest-journey)
6. [Authentication Flow](#6-authentication-flow)
7. [Room Browsing & Booking Flow](#7-room-browsing--booking-flow)
8. [Feature Gating System](#8-feature-gating-system)
9. [Features Reference](#9-features-reference)
10. [Services Layer](#10-services-layer)
11. [Models Reference](#11-models-reference)
12. [Backend API Endpoints](#12-backend-api-endpoints)
13. [Theme & Styling](#13-theme--styling)
14. [Error Handling Patterns](#14-error-handling-patterns)
15. [Environment Configuration](#15-environment-configuration)
16. [Database Migrations](#16-database-migrations)

---

## 1. Project Structure

```
lapirogue_hotel/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── app.dart                           # GoRouter + Riverpod wrapper
│   ├── core/
│   │   ├── models/                        # 17 data models
│   │   ├── services/                      # 14 service singletons
│   │   ├── theme/                         # Colors, typography, theme data
│   │   ├── widgets/                       # Reusable widgets (ReservationGate, etc.)
│   │   └── router/                        # GoRouter + MainShell (bottom nav)
│   ├── data/
│   │   └── providers/                     # Riverpod providers (auth, reservation, hotel, etc.)
│   └── features/
│       ├── auth/screens/                  # Login, register, OTP, onboarding, forgot password
│       ├── home/screens/                  # Main home screen
│       ├── rooms/screens/                 # Room list + detail + booking
│       ├── reservations/screens/          # Reservation list
│       ├── activities/screens/            # Activity browsing + booking
│       ├── dining/screens/                # Restaurant menu + ordering
│       ├── spa/screens/                   # Spa treatments (static)
│       ├── room_service/screens/          # Room service (static)
│       ├── messages/screens/              # Guest-staff chat (realtime)
│       ├── notifications/screens/         # Notification list
│       ├── schedule/screens/              # Daily schedule itinerary
│       ├── payments/screens/              # Billing + payment history
│       ├── feedback/screens/              # Guest feedback submission
│       ├── gallery/screens/               # Hotel photo gallery
│       ├── hotel_info/screens/            # About, services, emergency contacts
│       └── profile/screens/               # Profile, settings, privacy, help, support
└── assets/config/
    └── settings.json                      # Backend URL configuration
```

---

## 2. Architecture & Data Flow

### Three-Tier Architecture

```
┌────────────────────────────────────────────────┐
│                FLUTTER APP                      │
│                                                  │
│  Screens  ←→  Providers  ←→  Services  ←→  Supabase  │
│  (UI)      (state)     (queries)   (DB)        │
│                                                  │
│         ───────────────────────────              │
│         Custom Backend API (Next.js)             │
│         /api/reservations/*                      │
│         /api/activities/book                     │
│         /api/food-orders                         │
└────────────────────────────────────────────────┘
```

### Data Flow Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| **Supabase Direct** | CRUD queries via supabase_flutter | `Supabase.from('rooms').select('*')` |
| **Supabase RPC** | Stored procedure calls | `supabase.rpc('get_available_rooms', params)` |
| **Supabase Realtime** | Live subscriptions | `Supabase.from('messages').stream()` |
| **Custom API (Next.js)** | OTP verification, complex booking | `POST /api/reservations/verify-otp` |

---

## 3. State Management

### Provider Architecture (Riverpod)

```
Provider                  Type                      Purpose
───────────────────────────────────────────────────────────
authStateProvider         StateNotifierProvider     Auth state + guest data
authLoadingProvider       Provider<bool>            Convenience loading flag
reservationProvider       StateNotifierProvider     Reservation CRUD + status
allRoomsProvider          FutureProvider            All rooms
featuredRoomsProvider     FutureProvider            Featured rooms (limit 5)
roomByIdProvider          FutureProvider.family     Single room by ID
activitiesProvider        FutureProvider            Active activities
menuItemsProvider         FutureProvider            Available menu items
notificationsProvider     StreamProvider            Real-time notifications
messagesProvider          StreamProvider            Real-time messages
messagesControllerProvider Provider<MessagesController> Send message action
themeModeProvider         StateNotifierProvider     Dark/light mode toggle
```

### Auth State (AuthState)

```dart
class AuthState {
  AuthStatus status;        // unauthenticated | authenticated | loading
  Guest? guest;              // Current guest profile or null
  bool isLoading;
  String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsOnboarding => isAuthenticated && guest == null;
}
```

### Reservation State (ReservationState)

```dart
class ReservationState {
  ReservationStatus status;  // noReservation | pending | reserved | checkedIn |
                             // checkedOut | cancelled
  List<Reservation> reservations;
  Reservation? activeReservation;
  bool isLoading;
  String? error;

  // Computed gates
  bool get hasActiveReservation => activeReservation != null;
  bool get isCheckedIn => status == ReservationStatus.checkedIn;
  bool get canUseServices =>
      status == ReservationStatus.checkedIn ||
      status == ReservationStatus.reserved;
}
```

---

## 4. Navigation & Routing

### GoRouter Configuration

Declarative routing with shell routes for bottom navigation and auth redirect guards.

### Bottom Navigation Shell (4 tabs)

| Index | Tab | Route | Screen |
|-------|-----|-------|--------|
| 0 | Home | `/` | HomeScreen |
| 1 | Reservations | `/reservations` | ReservationsScreen |
| 2 | Messages | `/messages` | MessagesScreen |
| 3 | Profile | `/profile` | ProfileScreen |

### Route Table (pushed on root navigator)

| Route | Screen | Parameters (via `state.extra`) |
|-------|--------|--------------------------------|
| `/login` | LoginScreen | — |
| `/register` | RegisterScreen | — |
| `/email-verification` | EmailVerificationScreen | `email`, `verificationType`, `verificationId` |
| `/onboarding` | OnboardingScreen | — |
| `/forgot-password` | ForgotPasswordScreen | — |
| `/rooms` | RoomsListScreen | — |
| `/rooms/:id` | RoomDetailScreen | `checkIn`, `checkOut`, `nights` |
| `/dining` | DiningScreen | — |
| `/activities` | ActivitiesScreen | — |
| `/spa` | SpaScreen | — |
| `/gallery` | GalleryScreen | — |
| `/room-service` | RoomServiceScreen | — |
| `/notifications` | NotificationsScreen | — |
| `/feedback` | FeedbackScreen | — |
| `/hotel-info` | HotelInfoScreen | — |
| `/daily-schedule` | DailyScheduleScreen | — |
| `/payments` | PaymentsScreen | — |
| `/payment-methods` | PaymentMethodsScreen | — |
| `/settings` | SettingsScreen | — |
| `/privacy` | PrivacyScreen | — |
| `/help` | HelpScreen | — |
| `/contact-support` | ContactSupportScreen | — |

### Auth Redirect Logic

```
unauthenticated + auth route (/login, /register, /forgot-password)
    → allow

authenticated + auth route
    → redirect to /

authenticated + guest == null + not /onboarding
    → redirect to /onboarding

authenticated + guest != null + at /onboarding
    → redirect to /
```

---

## 5. Complete Guest Journey

```
┌──────────────────────────────────────────────────────────────────────┐
│                  1. DISCOVERY (No Auth Required)                       │
├──────────────────────────────────────────────────────────────────────┤
│  Home → Browse featured rooms → View room details                    │
│       → Browse activities → Browse food menu                         │
│       → View gallery → View hotel info → Emergency contacts          │
└──────────────────────────────────────┬───────────────────────────────┘
                                       │
                     User taps "Book This Room"
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  2. AUTHENTICATION                                    │
├──────────────────────────────────────────────────────────────────────┤
│  Not logged in? → Auth Sheet (Login / Create Account)                 │
│                                                                      │
│  ┌─ Register ──────────────────────────────────────────────────────┐ │
│  │  Step 1: Email + Password → Supabase Auth signUp                │ │
│  │  Step 2: 6-digit OTP verification → email_verification_screen   │ │
│  │  Step 3: Onboarding form (name, phone, nationality, passport,   │ │
│  │          DOB, gender) → RPC create_guest_profile                │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌─ Login ─────────────────────────────────────────────────────────┐ │
│  │  Email + Password → Supabase signInWithPassword → Load guest    │ │
│  │  Forgot password → resetPasswordForEmail                        │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────┬───────────────────────────────┘
                                       │
                                     Logged in
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  3. BOOKING                                           │
├──────────────────────────────────────────────────────────────────────┤
│  Room Detail Screen:                                                 │
│    → Select check-in / check-out dates                               │
│    → Select adults / children count                                  │
│    → See total price (price per night × nights)                      │
│    → Tap "Book This Room"                                            │
│                                                                      │
│  ┌─ OTP Verification Flow ─────────────────────────────────────────┐ │
│  │  1. POST /api/reservations/request-verification                 │ │
│  │     Payload: { guestId, roomId, checkIn, checkOut, adults,      │ │
│  │               children, totalAmount, origin: 'MOBILE_APP',      │ │
│  │               email }                                           │ │
│  │     → Backend validates guest                                   │ │
│  │     → Backend checks room availability                          │ │
│  │     → Backend calls RPC create_pending_reservation()            │ │
│  │     → Backend sends OTP via supabase.auth.signInWithOtp()       │ │
│  │     → Returns { verificationToken, expiresInSeconds, email }    │ │
│  │                                                                 │ │
│  │  2. Email Verification Screen (6-digit OTP input)               │ │
│  │     → User enters OTP + taps "Confirm Reservation"              │ │
│  │     → POST /api/reservations/verify-otp                         │ │
│  │     Payload: { email, token: verificationToken, code: OTP }     │ │
│  │     → Backend verifies OTP via supabase.auth.verifyOtp()        │ │
│  │     → Backend calls RPC verify_pending_reservation()            │ │
│  │     → Reservation created with status 'RESERVED'                │ │
│  │     → Confirmation email sent via Resend                        │ │
│  │     → Returns { reservationId, checkIn, checkOut, message }     │ │
│  │                                                                 │ │
│  │  3. Navigate to /reservations → Guest sees their new booking    │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────┬───────────────────────────────┘
                                       │
                              Reservation = 'RESERVED'
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  4. POST-BOOKING (Reservation Required)               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ✅ Activities (/activities)                                         │
│     Browse + book activities/tours within reservation date range     │
│     API: POST /api/activities/book                                  │
│                                                                      │
│  ✅ Messages (/messages)                                             │
│     Real-time chat with hotel staff                                  │
│     Realtime: Supabase messages table stream                        │
│                                                                      │
│  ✅ Daily Schedule (/daily-schedule)                                 │
│     View itinerary (limited preview before check-in)                 │
│     Full unlock after check-in                                      │
│                                                                      │
│  ✅ Notifications (/notifications)                                   │
│     Real-time hotel notifications                                   │
│                                                                      │
│  ✅ Reservations (/reservations)                                     │
│     View all reservations, status badges, payment links              │
└──────────────────────────────────────┬───────────────────────────────┘
                                       │
                              Guest arrives at hotel
                              → Check-in at reception
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  5. POST-CHECK-IN (Checked In Required)               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ✅ Dining (/dining)                                                 │
│     Browse restaurant menu → place food order                        │
│     API: POST /api/food-orders                                      │
│                                                                      │
│  ✅ Room Service (/room-service)                                     │
│     View room service categories (static UI)                         │
│                                                                      │
│  ✅ Spa (/spa)                                                       │
│     View treatment list (static UI)                                  │
│                                                                      │
│  ✅ Schedule (/daily-schedule)                                       │
│     Full itinerary: activity bookings, food orders, events           │
│     Mark items complete → earn eco-points (25 pts each)             │
│     Auto-complete overdue items on load                             │
└──────────────────────────────────────┬───────────────────────────────┘
                                       │
                              Check-out at hotel
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  6. ONGOING (Any Auth State)                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ✅ Payments (/payments)                                             │
│     View billing summary, payment history, breakdown by category     │
│                                                                      │
│  ✅ Feedback (/feedback)                                             │
│     Submit rating + comment                                          │
│                                                                      │
│  ✅ Profile (/profile)                                               │
│     Manage photo, dark mode, sign out                                │
│                                                                      │
│  ✅ Settings (/settings)                                             │
│     Notification preferences, language, cache, version               │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 6. Authentication Flow

### Registration (3-Step)

| Step | Screen | Action | API Call |
|------|--------|--------|----------|
| 1 | `/register` | Enter email + password | `supabase.auth.signUp(email, password)` |
| 2 | `/email-verification` | Enter 6-digit OTP | `supabase.auth.verifyOTP(email, code, OtpType.signup)` |
| 2b | `/email-verification` | Resend OTP | `supabase.auth.resend(email, type: OtpType.signup)` |
| 3 | `/onboarding` | Fill profile form | `supabase.rpc('create_guest_profile', { firstName, lastName, phone, nationality, passport, dob, gender })` |

### Login

| Action | API Call |
|--------|----------|
| Email + password login | `supabase.auth.signInWithPassword(email, password)` |
| Load guest after login | `supabase.from('guests').select('*, reservations(*, rooms(*))').eq('auth_id', authId)` |
| Forgot password | `supabase.auth.resetPasswordForEmail(email)` |

### Auth State Persistence

- `Supabase.instance.client.auth.onAuthStateChange` listener in `AuthNotifier._init()`
- On app restart: checks existing Supabase session → loads guest profile
- Session managed by Supabase (stored in secure storage)

---

## 7. Room Browsing & Booking Flow

### Room Listing (`/rooms`)

1. User selects check-in and check-out dates (date pickers)
2. User taps "Check Availability"
3. Calls RPC: `get_available_rooms(p_check_in, p_check_out)`
4. Fallback: if RPC fails, filters rooms by `status == 'AVAILABLE'`
5. Each room card shows: image, type, room number, price/night, capacity, amenities (max 3), total for selected nights
6. Tapping a room → `/rooms/:id` with `{ checkIn, checkOut, nights }`

### Room Detail (`/rooms/:id`)

**Screen sections:**
- Hero image with room type badge
- Room number and capacity
- Price per night
- Description
- Amenities chips
- Booking Details section:
  - Check-in date picker (minimum: tomorrow)
  - Check-out date picker (minimum: check-in + 1 day)
  - Adults counter (1–10)
  - Children counter (0–10)
  - Total price = price × nights
- "Book This Room" button

**Booking flow (`_handleBooking`):**
1. If not authenticated → show `AuthSheet` (bottom sheet with Login/Create Account)
2. If authenticated → call `_requestReservationVerification()`
3. POST to custom backend with booking details
4. On success → navigate to `/email-verification` with `{ email, verificationType: 'reservation', verificationId }`
5. On failure → show SnackBar with error message

### Reservation Verification Emails

The system uses Supabase Auth's built-in email OTP (6-digit code) for reservation verification:

1. Backend calls `supabase.auth.signInWithOtp({ email, options: { emailRedirectTo } })`
2. Guest receives email with 6-digit code
3. Guest enters code in email verification screen
4. Backend calls `supabase.auth.verifyOtp({ email, token: code, type: 'email' })`
5. On success, RPC `verify_pending_reservation()` creates the actual reservation

### Resending Verification Code

- Guest can request resend on email verification screen
- POST `/api/reservations/resend-otp` with `{ email, token: verificationId }`
- Backend calls `supabase.auth.signInWithOtp({ email })` again

---

## 8. Feature Gating System

### ReservationGate Widget

The `ReservationGate` widget wraps features that require authentication or an active reservation.

| Gate Level | Condition | UI Shown |
|------------|-----------|----------|
| **Not Authenticated** | User not logged in | Lock overlay: "Sign In Required" → tap triggers `showAuthSheet()` |
| **No Reservation** | Logged in but no active reservation | Lock overlay: "No Reservation" + "Book a Room" button → navigates to `/rooms` |
| **Pre Check-In** | Has reservation but not checked in | Lock overlay: "Available After Check-In" (only if `requiresCheckIn: true`) |

### Feature Gating Matrix

| Feature | Route | Gate Applied | `requiresCheckIn` | Notes |
|---------|-------|-------------|-------------------|-------|
| Home | `/` | None | — | Partial: activity booking checks reservation inline |
| Room List | `/rooms` | None | — | Open to all |
| Room Detail | `/rooms/:id` | Auth check | — | Auth sheet shown on "Book" tap |
| Activities | `/activities` | `ReservationGate` | `false` | Browse any time; book with any reservation |
| Reservations | `/reservations` | Auth check | — | Login prompt if not authenticated |
| Messages | `/messages` | Manual check | — | Requires reservation for messaging feature |
| Dining | `/dining` | `ReservationGate` | `true` | Locked until check-in |
| Spa | `/spa` | `ReservationGate` | `true` | Locked until check-in |
| Room Service | `/room-service` | `ReservationGate` | `true` | Locked until check-in |
| Schedule | `/daily-schedule` | Manual check | — | Full unlock after check-in |
| Notifications | `/notifications` | Auth check | — | Login prompt if not authenticated |
| Payments | `/payments` | Auth check | — | Shows data if logged in |
| Feedback | `/feedback` | None | — | Open to all (uses guest ID if available) |
| Gallery | `/gallery` | None | — | Open to all |
| Hotel Info | `/hotel-info` | None | — | Open to all |
| Profile | `/profile` | Auth check | — | Login prompt if not authenticated |
| Settings | `/settings` | None | — | Open to all |

---

## 9. Features Reference

### 9.1 Home (`/`)

The guest's landing screen with time-based greeting and quick-access carousels.

- **Greeting:** "Good Morning/Afternoon/Evening, [Name]" with reservation status badge
- **Search bar:** Room search via Supabase (filters by number/type/description) → bottom sheet results
- **Featured Rooms Carousel:** Top 5 available SUITE/VILLA rooms
- **Facilities Grid:** 7 icons (Swimming Pool, Beach, Spa, Restaurant, Gym, Kids Club, Conference)
- **Activities Carousel:** Browse + quick book activities
- **Food & Beverages Carousel:** Browse menu items
- **Notification Bell:** Top-right → `/notifications` (or auth sheet if not logged in)

### 9.2 Room List (`/rooms`)

Room availability search with date selection.

- **Date pickers:** Check-in (min: tomorrow) and Check-out (min: check-in + 1 day)
- **"Check Availability" button:** Calls RPC `get_available_rooms` with fallback to `status == 'AVAILABLE'` filter
- **Room cards:** Image, type badge, room number, price/night, capacity, amenities chips
- **Navigation:** Tap card → `/rooms/:id` with check-in/out and nights in extras

### 9.3 Room Detail (`/rooms/:id`)

Full room view with booking controls.

- **Image header:** CachedNetworkImage with gradient overlay
- **Details:** Type badge, room number, capacity, description, amenities chips
- **Booking section:** Date pickers, guest counters, total price
- **"Book This Room" button:** Starts the OTP verification booking flow

### 9.4 Activities (`/activities`)

Browse and book hotel activities.

- **Gating:** `ReservationGate(requiresCheckIn: false)` — browse freely, book with any reservation
- **Activity cards:** Image, name, category chip, duration, price, capacity status
- **Booking:** Bottom sheet with date picker (constrained to reservation dates), participants counter
- **API:** `POST /api/activities/book`

### 9.5 Dining (`/dining`)

Restaurant menu browsing and food ordering.

- **Gating:** `ReservationGate(requiresCheckIn: true)`
- **Menu:** Items grouped by category from `menu_items` table
- **Ordering:** Bottom sheet with quantity, special instructions, total display
- **API:** `POST /api/food-orders`

### 9.6 Messages (`/messages`)

Real-time chat with hotel staff (one of 4 bottom nav tabs).

- **Gating:** Manual — requires reservation
- **Data:** Real-time `Supabase.from('messages').stream()` filtered by `guest_id`
- **Features:** Staff messages left-aligned (gray), guest messages right-aligned (blue), timestamps, file attachments
- **Send:** Text input + send button

### 9.7 Reservations (`/reservations`)

List of all guest reservations (one of 4 bottom nav tabs).

- **Gating:** Auth check (login prompt if not authenticated)
- **Data:** `Supabase.from('reservations').select('*, rooms(*)').eq('guest_id', guestId)`
- **Cards:** Status badge (color-coded), reservation ID, dates, guests, total, "View Payment" button
- **Status colors:** Confirmed (green), pending (orange), cancelled (red), checked-in (blue), checked-out (gray)

### 9.8 Daily Schedule (`/daily-schedule`)

Aggregated itinerary from multiple data sources.

- **Data sources:** `guest_schedule_items`, `activity_bookings`, `food_orders`, `guest_orders`, `itinerary_events`, `reservations`
- **Navigation:** Day-by-day arrows + date picker
- **Items:** Color-coded by type (ACTIVITY, ORDER, RESERVATION) with status badges
- **Eco-points:** Mark items complete → 25 eco-points with animation dialog
- **Auto-complete:** Overdue items auto-completed on screen load

### 9.9 Notifications (`/notifications`)

Real-time notification inbox.

- **Data:** `Supabase.from('notifications').stream()` filtered by `guest_id`
- **Features:** Category icons, relative timestamps, unread indicator, "Mark All Read"

### 9.10 Payments (`/payments`)

Billing summary and payment history.

- **Data:** Aggregated from 5+ tables via `BillingService.getBillingSummary()`
- **Sections:** Billing status card (PAID/PARTIALLY_PAID/PENDING), summary cards (Total Charges, Total Paid, Balance Due), breakdown by category, payment history with expansion

### 9.11 Profile (`/profile`)

User profile management (one of 4 bottom nav tabs).

- **Gating:** Auth check (login prompt if not authenticated)
- **Photo:** Tap to upload via ImagePicker → Supabase Storage (`guest-photos` bucket) → update guest record
- **Sections:** Personal info, Support (Feedback), Hotel (Hotel Info, Reservations), Preferences (Dark Mode toggle, Language), Sign Out

---

## 10. Services Layer

All services follow the **Singleton** pattern:

```dart
class ServiceName {
  static final ServiceName _instance = ServiceName._internal();
  factory ServiceName() => _instance;
  ServiceName._internal();
}
```

### Service Reference

| Service | Primary Functions | Backend |
|---------|------------------|---------|
| **AuthService** | `baseUrl` (loads from `settings.json`) | Asset config file |
| **SupabaseService** | `signInWithPassword`, `signUp`, `signOut`, `resetPasswordForEmail`, guest CRUD, RPC wrappers | Supabase Auth + REST |
| **SessionService** | `currentSession`, `currentUser`, `getCurrentGuest`, `onAuthStateChange` | Supabase Auth |
| **GuestService** | `getCurrentGuest`, `getGuestById`, `updateGuest`, `updateProfileImagePath`, unread counts | Supabase `guests` table |
| **ActivityService** | `getAvailableActivities`, `markActivityCompleted` | Supabase `activities` table |
| **EcoPointsService** | `getEcoPointsBalance`, `getEcoPointsTier`, `getTransactions`, `getLeaderboard`, `earnPoints` | Supabase RPCs + tables |
| **BillingService** | `getBillingSummary` (aggregates from 5+ tables) | Supabase multi-table queries |
| **PaymentService** | `getPayments`, `getTotalPaid`, `getTotalOutstanding` | Supabase `payments` table |
| **FoodService** | `getMenuItems` | Supabase `menu_items` table |
| **ContentService** | `getPage`, `getServiceCategories`, `getHotelServices`, `getEmergencyContacts` | Supabase CMS tables |
| **MessageService** | `getMessages`, `sendMessage`, `markAsRead`, `getUnreadCount` (supports file attachments) | Supabase `messages` table |
| **NotificationService** | `getNotifications`, `markAsRead`, `markAllAsRead` | Supabase `notifications` table |
| **PushNotificationService** | `initialize` (FCM + local), notification stream, token storage | Firebase + Supabase |
| **ScheduleService** | `getScheduleForGuest` (6-table agg), `getTodaysSchedule`, `markItemCompleted`, `autoCompleteOverdueItems` | Supabase multi-table + RPC |
| **StorageService** | `uploadGuestPhoto` (bucket: `guest-photos`), `uploadChatFile` (bucket: `chat_uploads`) | Supabase Storage |

---

## 11. Models Reference

| Model | Supabase Table | Key Fields |
|-------|---------------|------------|
| `Guest` | `guests` | id, authId, guestId, firstName, lastName, email, phone, nationality, passport, dateOfBirth, gender, status, accountStatus, imagePath, reservations[] |
| `Room` | `rooms` | id, roomNumber, type, floor, capacity, price, status, description, amenities[], imagePath, imagePaths[] |
| `Reservation` | `reservations` | id, reservationId, guestId, roomId, checkIn, checkOut, adults, children, status, totalAmount, notes, origin, room |
| `Activity` | `activities` | id, name, category, description, price, duration, capacity, status, imagePath, meetingPoint, defaultTime |
| `ActivityBooking` | `activity_bookings` | id, activityId, guestId, bookingDate, bookingTime, participants, status, pickupPoint, notes, origin, activity |
| `MenuItem` | `menu_items` | id, name, category, description, price, preparationMinutes, isAvailable, imagePath |
| `FoodOrder` | `food_orders` | id, orderId, guestId, roomId, items[], subtotal, serviceCharge, taxAmount, total, status, notes, origin |
| `Message` | `messages` | id, guestId, senderType, content, isRead, createdAt, fileUrl, fileName |
| `AppNotification` | `notifications` | id, guestId, title, message, category, isRead, createdAt |
| `GuestScheduleItem` | `guest_schedule_items` | id, guestId, title, itemType, startAt, endAt, location, description, status, color, sourceModule |
| `Payment` | `payments` | id, paymentId, guestId, reservationId, amount, method, status, reference, extraItems[] |
| `SiteContentPage` | `site_content_pages` | id, slug, title, subtitle, body, highlights[], metrics[], imagePath, isActive |
| `HotelService` | `hotel_services` | id, categoryId, name, description, phoneNumber, email, hoursText, location, imageUrl |
| `HotelServiceCategory` | `hotel_service_categories` | id, name, description, iconName, colorHex, displayOrder |
| `EmergencyContact` | `emergency_contacts` | id, name, description, phoneNumber, iconName, is24h, displayOrder |
| `EcoPointsBalance` | (computed) | guestId, points, tier |
| `EcoPointsTransaction` | `guest_eco_point_events` | id, guestId, sourceType, sourceLabel, points, carbonOffsetKg, status |
| `EcoAction` | `sustainability_activities` | id, name, category, description, defaultPoints, carbonOffsetKg, isActive |

---

## 12. Backend API Endpoints

### Custom Endpoints (Next.js at `backend_url`)

Configured in `assets/config/settings.json` → `backend_url`: `https://lapirogue-hotel.yunusu.me`

| Method | Endpoint | Request Body | Response (success) |
|--------|----------|-------------|-------------------|
| POST | `/api/reservations/request-verification` | `{ guestId, roomId, checkIn, checkOut, adults, children, totalAmount, origin: 'MOBILE_APP', email }` | `{ verificationToken, expiresInSeconds, email, message }` |
| POST | `/api/reservations/verify-otp` | `{ email, token: verificationToken, code: "123456" }` | `{ reservationId, checkIn, checkOut, message }` |
| POST | `/api/reservations/resend-otp` | `{ email, token: verificationToken }` | `{ message, expiresInSeconds }` |
| POST | `/api/activities/book` | `{ activityId, guestId, date, timeSlot, participants, status: 'CONFIRMED', origin: 'MOBILE_APP' }` | `{ success, bookingId }` |
| POST | `/api/food-orders` | `{ guestId, items[], subtotal, serviceCharge, taxAmount, total, notes, origin: 'MOBILE_APP' }` | `{ success, orderId }` |

### Supabase Direct Queries

The app communicates directly with Supabase for all CRUD operations on 22+ tables using the Supabase Flutter SDK.

### Supabase RPC Functions

| Function | Parameters | Purpose |
|----------|-----------|---------|
| `create_guest_profile` | firstName, lastName, phone, nationality, passport, dob, gender | Create guest record during onboarding |
| `get_available_rooms` | checkIn, checkOut | Room availability search |
| `lookup_guest_by_booking` | reservationId, lastName | Anonymous booking lookup |
| `link_guest_auth` | guestId, authId | Link auth to existing guest |
| `get_guest_eco_points` | guestId | Get eco-points balance |
| `get_eco_leaderboard` | limit | Sustainability leaderboard |
| `auto_complete_schedule_items` | — | Auto-complete overdue items |
| `create_pending_reservation` | guestId, email, roomId, checkIn, checkOut, adults, children, total, origin | Create pending reservation for OTP flow |
| `verify_pending_reservation` | token, authId | Verify OTP and create actual reservation |
| `cleanup_expired_pending_reservations` | — | Clean up expired pending reservations |
| `increment_eco_points` | guestId, points | Update eco-points balance |
| `create_mobile_reservation` | guestId, roomId, checkIn, checkOut, adults, children | Legacy direct mobile reservation (not used in current OTP flow) |

---

## 13. Theme & Styling

### Color System

| Token | Hex | Usage |
|-------|-----|-------|
| `oceanBlue` | `#003B5C` | Primary color, AppBar, active nav items |
| `goldAccent` | `#C9A96E` | Secondary/accent, "Book" buttons, highlights |
| `turquoise` | `#00B4D8` | Tertiary accent |
| `lightGray` | `#F5F5F0` | Surface backgrounds, cards |
| `statusConfirmed` | `#10B981` | RESERVED/CONFIRMED status badge |
| `statusPending` | `#F59E0B` | PENDING status badge |
| `statusCancelled` | `#EF4444` | CANCELLED status badge |
| `statusInfo` | `#3B82F6` | CHECKED_IN status badge |
| `textPrimary` | `#1A1A2E` | Primary text |
| `textSecondary` | `#6B7280` | Secondary text |
| `textTertiary` | `#9CA3AF` | Tertiary/hint text |

### Typography

- **Font:** DM Sans (Google Fonts)
- **Sizes:** Page Title (34–28), Section Header (24–20), Body (18–16), Button (18–14), Caption (14–12), Price (28–18)

### Theme Modes

| Mode | Primary | Secondary | Surface |
|------|---------|-----------|---------|
| Light | Ocean Blue `#003B5C` | Gold `#C9A96E` | White/Light Gray |
| Dark | Gold `#C9A96E` | Turquoise `#00B4D8` | Dark `#1A1A2E` |

Dark mode persisted via `SharedPreferences` and managed through `themeModeProvider`.

---

## 14. Error Handling Patterns

### Backend API Error Handling

All custom backend endpoints follow this pattern:

```typescript
export async function POST(request: NextRequest) {
  try {
    // 1. Parse request body (Zod validation)
    // 2. Business logic
    // 3. Return success
  } catch (error) {
    // 1. Check if validation error (ZodError)
    const validation = validationErrorResponse(error);
    if (validation) return validation;
    // 2. Return 500 with actual error message in dev mode
    return handleError(error, "Generic fallback message");
  }
}
```

The `handleError` function (`api-response.ts`):
- Logs the error server-side via `console.error`
- In `NODE_ENV=development`: returns the actual error message
- In `NODE_ENV=production`: returns the generic fallback message

### Mobile App Error Handling

```dart
try {
  final response = await http.post(url, ...).timeout(Duration(seconds: 30));
  // Handle non-JSON / HTML responses (server down detection)
  if (response.body.trimLeft().startsWith('<')) {
    throw Exception('Backend returned HTML error...');
  }
  // Handle API error response
  final payload = jsonDecode(response.body);
  if (response.statusCode >= 400 || payload['success'] != true) {
    throw Exception(payload['error'] ?? 'Failed...');
  }
  // Success path
} on TimeoutException catch (e) {
  throw Exception('Request timeout: ${e.message}');
} catch (e) {
  // Rethrow to caller for UI handling
  rethrow;
}
```

UI layer catches errors and displays via `SnackBar` with descriptive message and appropriate background color.

### Supabase Query Error Handling

```dart
final response = await supabase.from('table').select('*');
if (response.error != null) {
  debugPrint('Error: ${response.error.message}');
  // Graceful degradation or user-facing error
}
```

---

## 15. Environment Configuration

### Mobile App (`lapirogue_hotel/.env`)

```env
SUPABASE_URL=https://txalwdljaxltchcrauhp.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

### Mobile App (`lapirogue_hotel/assets/config/settings.json`)

```json
{
  "backend_url": "https://lapirogue-hotel.yunusu.me"
}
```

### Backend (`Hotel/.env`)

```env
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000

RESEND_API_KEY=re_...

NEXT_PUBLIC_SUPABASE_URL=https://txalwdljaxltchcrauhp.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=...

SUPABASE_URL=https://txalwdljaxltchcrauhp.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

**Required environment variables:**

| Variable | Used By | Purpose |
|----------|---------|---------|
| `SUPABASE_URL` | Mobile + Backend | Supabase project URL |
| `SUPABASE_ANON_KEY` | Mobile | Supabase anon key (client-side) |
| `SUPABASE_SERVICE_ROLE_KEY` | Backend | Supabase service role key (server-side, admin) |
| `NEXT_PUBLIC_APP_URL` | Backend | Base URL for email redirect links |
| `RESEND_API_KEY` | Backend | Resend email service API key |

---

## 16. Database Migrations

### Supabase Tables Created by Migrations

The database is set up via sequential SQL migration files:

| Migration | Key Objects Created |
|-----------|-------------------|
| `laprogue_final.sql` (base schema) | All base tables: `guests`, `rooms`, `reservations`, `activities`, `activity_bookings`, `menu_items`, `food_orders`, `messages`, `notifications`, `guest_schedule_items`, `payments`, `guest_feedback`, `site_content_pages`, `hotel_services`, `emergency_contacts`, `eco_points_balance`, `eco_points_tx`, `guest_eco_actions`, `itinerary_events`, `audit_logs`, `roles` |
| `guest_app_migration_v3.sql` | Guest app improvements: RPCs for guest profile creation, food ordering, activity booking |
| `supabase_migration_v7.sql` | `gender` column, `account_status` column, `'RESERVED'` in `reservation_status` enum, cancellation triggers, `get_available_rooms` RPC, `create_mobile_reservation` RPC, `create_guest_profile` RPC, `book_activity_pre_checkin` RPC |
| `migrations/008_pending_reservations_fix.sql` | `order_origin` enum type, `origin` columns on `reservations` and `activity_bookings`, `pending_reservations` table, `create_pending_reservation` RPC, `verify_pending_reservation` RPC, `cleanup_expired_pending_reservations` RPC |

### Reservation OTP Flow Architecture

```
pending_reservations           reservations
┌──────────────────────┐       ┌──────────────────────┐
│ id (PK)              │       │ id (PK)              │
│ email                │       │ reservation_id       │
│ guest_id (FK)        │       │ guest_id (FK)        │
│ room_id (FK)         │       │ room_id (FK)         │
│ check_in             │       │ check_in             │
│ check_out            │       │ check_out            │
│ adults               │       │ adults               │
│ children             │       │ children             │
│ total_amount         │──→    │ total_amount         │
│ origin (text)        │       │ status: 'RESERVED'   │
│ verification_token   │       │ origin (order_origin) │
│ verified_at          │       │ created_at           │
│ expires_at (30 min)  │       └──────────────────────┘
│ created_at           │
└──────────────────────┘

Flow:
1. Guest initiates booking → insert into pending_reservations
2. Guest verifies OTP → move to reservations with status 'RESERVED'
3. Expired records cleaned up by cleanup_expired_pending_reservations()
```

### Migration Runner

Script: `Hotel/scripts/run_migration.mjs`

Connects to Supabase PostgreSQL via service role key and runs SQL files sequentially:

```bash
cd Hotel
node scripts/run_migration.mjs
```

Files run in order:
1. `supabase/cleanup_complete.sql`
2. `supabase/laprogue_v2_migration.sql`
3. `supabase/supabase_migration_v7.sql`
4. `supabase/migrations/008_pending_reservations_fix.sql`
