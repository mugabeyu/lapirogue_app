import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/content_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/models/guest.dart';
import '../../../core/models/site_content_page.dart';
import '../../../core/models/guest_schedule_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../activities/screens/activities_screen.dart';
import '../../food/screens/food_beverage_screen.dart';
import '../../schedule/screens/daily_schedule_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../payments/screens/payments_screen.dart';
import '../../hotel_info/screens/hotel_info_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Guest? _guest;
  SiteContentPage? _hotelInfo;
  List<UpcomingItem> _upcomingItems = [];
  BillingSummary? _billing;
  int _ecoPoints = 0;
  String _ecoPointsTier = 'Bronze';
  bool _isLoading = true;
  int _unreadNotifications = 0;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    if (hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }

  String get _weatherIcon {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return '\u2600\uFE0F';
    if (hour >= 12 && hour < 17) return '\u26C5';
    if (hour >= 17 && hour < 20) return '\uD83C\uDF05';
    return '\uD83C\uDF19';
  }

  String get _weatherDesc {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Sunny';
    if (hour >= 12 && hour < 17) return 'Partly Cloudy';
    if (hour >= 17 && hour < 20) return 'Clear Evening';
    return 'Clear Sky';
  }



  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final guest = await GuestService().getCurrentGuest();
    if (guest == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        ContentService().getPage('about'),
        ScheduleService().getScheduleForGuest(guest.id, fromDate: _todayStart, toDate: _todayEnd),
        BillingService().getBillingSummary(guest.id),
        EcoPointsService().getEcoPointsBalance(guest.id),
        EcoPointsService().getEcoPointsTier(guest.id),
        GuestService().getUnreadNotificationsCount(guest.id),
      ]);

      final hotelInfo = results[0] as SiteContentPage?;
      final scheduleItems = results[1] as List<GuestScheduleItem>;
      final billing = results[2] as BillingSummary;
      final ecoPoints = results[3] as int;
      final ecoTier = results[4] as String;
      final unreadNotif = results[5] as int;

      var upcoming = <UpcomingItem>[];
      for (final item in scheduleItems) {
        if (item.status.toUpperCase() == 'COMPLETED') continue;
        final icon = _itemTypeIcon(item.itemType);
        final color = Color(int.parse(item.color.replaceFirst('#', '0xFF')));
        upcoming.add(UpcomingItem(
          id: item.id,
          time: item.startAt,
          title: item.title,
          subtitle: item.location,
          icon: icon,
          color: color,
        ));
      }
      upcoming.sort((a, b) => a.time.compareTo(b.time));
      if (upcoming.length > 2) {
        upcoming = upcoming.sublist(0, 2);
      }

      if (mounted) {
        setState(() {
          _guest = guest;
          _hotelInfo = hotelInfo;
          _upcomingItems = upcoming;
          _billing = billing;
          _ecoPoints = ecoPoints;
          _ecoPointsTier = ecoTier;
          _unreadNotifications = unreadNotif;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _guest = guest;
          _isLoading = false;
        });
      }
    }
  }

  IconData _itemTypeIcon(String itemType) {
    switch (itemType) {
      case 'SPA': return Icons.spa;
      case 'DINING': return Icons.restaurant;
      case 'ACTIVITY': return Icons.explore;
      case 'TOUR': return Icons.sailing;
      case 'TRANSPORT': return Icons.airport_shuttle;
      case 'FITNESS': return Icons.fitness_center;
      case 'SWIMMING': return Icons.pool;
      default: return Icons.event;
    }
  }

  DateTime get _todayStart => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime get _todayEnd => _todayStart.add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildNavBar(),
                    _buildWelcomeSection(),
                    _buildHeroSection(),
                    _buildStayInfoCard(),
                    _buildExploreSection(),
                    _buildUpcomingToday(),
                    _buildPaymentBilling(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 100,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: AppTheme.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/lapirogue_logo.jpg',
                  height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'La Pirogue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Hotel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifications.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarText() {
    final initial = (_guest?.firstName.isNotEmpty == true ? _guest!.firstName[0] : 'G').toUpperCase();
    return Text(
      initial,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primary,
            child: _guest?.imagePath != null && _guest!.imagePath!.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _guest!.imagePath!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _buildAvatarText(),
                      errorWidget: (_, _, _) => _buildAvatarText(),
                    ),
                  )
                : _buildAvatarText(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _guest?.fullName.isNotEmpty == true ? _guest!.fullName : 'Guest',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('\uD83C\uDF34', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _hotelInfo?.subtitle ?? _hotelInfo?.body?.split('\n').first ?? 'Enjoy your stay',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(_weatherIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  _weatherDesc,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final hasImage = _hotelInfo?.imagePath != null && _hotelInfo!.imagePath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotelInfoScreen()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                if (hasImage)
                  CachedNetworkImage(
                    imageUrl: _hotelInfo!.imagePath!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _buildHeroGradient(),
                  )
                else
                  _buildHeroGradient(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container _buildHeroGradient() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primary,
          ],
        ),
      ),
    );
  }

  Widget _buildStayInfoCard() {
    final reservation = _guest?.reservations?.isNotEmpty == true
        ? _guest!.reservations!.firstWhere(
            (r) => r.status.toUpperCase() == 'CONFIRMED',
            orElse: () => _guest!.reservations!.first,
          )
        : null;

    final roomNumber = reservation?.room?.roomNumber ?? '--';
    final roomType = reservation?.room?.type ?? '';
    final checkoutDate = reservation?.checkOut != null
        ? DateFormat('d MMMM yyyy').format(reservation!.checkOut)
        : '--';
    final checkoutTime = reservation?.checkOut != null && reservation!.checkOut.hour > 0
        ? DateFormat('HH:mm').format(reservation.checkOut)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.door_front_door_outlined, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Room $roomNumber',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (roomType.isNotEmpty)
                        Text(
                          roomType,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: VerticalDivider(color: AppTheme.borderLight, thickness: 1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: AppTheme.accentOrange, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        checkoutDate,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (checkoutTime != null)
                        Text(
                          checkoutTime,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: VerticalDivider(color: AppTheme.borderLight, thickness: 1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.eco, color: AppTheme.accentGreen, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$_ecoPoints Points',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                      Text(
                        _ecoPointsTier,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExploreSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Your Stay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildExploreCard(
                icon: Icons.explore,
                label: 'Activities & Tours',
                subtitle: 'Book experiences',
                bgColor: const Color(0xFFE8F0FE),
                iconColor: const Color(0xFF1A73E8),
                route: const ActivitiesScreen(),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildExploreCard(
                icon: Icons.room_service_outlined,
                label: 'Food & Beverage',
                subtitle: 'Order food & drinks',
                bgColor: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFF4A340),
                route: const FoodBeverageScreen(),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildExploreCard(
                icon: Icons.calendar_today_outlined,
                label: 'Daily Schedule',
                subtitle: "View today's itinerary",
                bgColor: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
                route: const DailyScheduleScreen(),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required Widget route,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => route));
          if (mounted) _loadAll();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingToday() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\uD83C\uDF34 Upcoming Today',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (_upcomingItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy, size: 36, color: AppTheme.textTertiary),
                  SizedBox(height: 8),
                  Text(
                    'Nothing scheduled today',
                    style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explore activities and tours above',
                    style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(_upcomingItems.length, (i) {
                  final item = _upcomingItems[i];
                  final isLast = i == _upcomingItems.length - 1;
                  return _buildUpcomingItem(item, isLast: isLast);
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem(UpcomingItem item, {bool isLast = false}) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyScheduleScreen()),
            );
            if (mounted) _loadAll();
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('d MMM').format(item.time),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(item.time),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 4),
          Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildPaymentBilling() {
    if (_billing == null) return const SizedBox.shrink();
    final b = _billing!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_outlined, size: 18, color: AppTheme.textPrimary),
                  const SizedBox(width: 6),
                  const Text(
                    'Payment & Billing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildBillColumn('Charges', 'Rs ${b.totalCharges.toStringAsFixed(0)}', AppTheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBillColumn('Paid', 'Rs ${b.totalPaid.toStringAsFixed(0)}', AppTheme.accentGreen)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBillColumn(
                    'Due',
                    'Rs ${b.balanceDue.toStringAsFixed(0)}',
                    b.balanceDue > 0 ? AppTheme.accentOrange : AppTheme.accentGreen,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen())),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillColumn(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class UpcomingItem {
  final String id;
  final DateTime time;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const UpcomingItem({
    required this.id,
    required this.time,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
  });
}
