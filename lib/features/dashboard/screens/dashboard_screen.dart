import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/guest_service.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/services/schedule_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/message.dart';
import '../../../core/models/guest_schedule_item.dart';
import '../../../core/models/guest.dart';
import '../widgets/dashboard_card.dart';
import '../../schedule/screens/daily_schedule_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../notifications/screens/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  bool _isLoading = true;
  String _guestName = '';
  String _roomNumber = '--';
  String _roomType = '';
  String _checkInDate = '';
  String _checkOutDate = '';
  String _reservationStatus = 'CONFIRMED';
  int _ecoPoints = 0;
  List<GuestScheduleItem> _todaySchedule = [];
  List<Message> _latestMessages = [];

  Guest? _guest;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _guest = await GuestService().getCurrentGuest();
    if (_guest == null) {
      setState(() => _isLoading = false);
      return;
    }

    final guestId = _guest!.id;
    
    final results = await Future.wait([
      GuestService().getUnreadNotificationsCount(guestId),
      GuestService().getUnreadMessagesCount(guestId),
      EcoPointsService().getEcoPointsBalance(guestId),
      ScheduleService().getTodaysSchedule(guestId),
      MessageService().getMessages(guestId),
    ]);

    final reservation = _guest!.reservations?.isNotEmpty == true ? _guest!.reservations![0] : null;

    setState(() {
      _guestName = _guest!.fullName.isNotEmpty ? _guest!.fullName : '';
      _unreadNotifications = results[0] as int;
      _unreadMessages = results[1] as int;
      _ecoPoints = results[2] as int;
      _todaySchedule = (results[3] as List<GuestScheduleItem>).take(3).toList();
      _latestMessages = (results[4] as List<Message>).take(3).toList();
      
      if (reservation != null) {
        _roomNumber = reservation.room?.roomNumber ?? '--';
        _roomType = reservation.room?.type ?? '';
        _checkInDate = reservation.checkIn.toIso8601String().split('T').first;
        _checkOutDate = reservation.checkOut.toIso8601String().split('T').first;
        _reservationStatus = reservation.status;
      }
      
      _isLoading = false;
    });
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Color _getStatusColor() {
    switch (_reservationStatus.toUpperCase()) {
      case 'CHECKED_IN':
        return AppTheme.statusConfirmed;
      case 'CONFIRMED':
        return AppTheme.statusPending;
      case 'CHECKED_OUT':
        return AppTheme.textSecondary;
      default:
        return AppTheme.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary,
                              AppTheme.primaryLight,
                            ],
                          ),
                        ),
                      ),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            _guestName.isNotEmpty ? _guestName : 'Guest',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => _navigateTo(const NotificationsScreen()),
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  _unreadNotifications.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.message_outlined),
                            onPressed: () => _navigateTo(const MessagesScreen()),
                          ),
                          if (_unreadMessages > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentRed,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  _unreadMessages.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DashboardCard(
                        title: 'Current Stay',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.hotel,
                                    color: AppTheme.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Room $_roomNumber',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      if (_roomType.isNotEmpty)
                                        Text(
                                          _roomType,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _reservationStatus,
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateInfo(
                                    'Check-in',
                                    _checkInDate.isNotEmpty ? _formatDate(_checkInDate) : '--',
                                    Icons.login,
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Expanded(
                                  child: _buildDateInfo(
                                    'Check-out',
                                    _checkOutDate.isNotEmpty ? _formatDate(_checkOutDate) : '--',
                                    Icons.logout,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  if (_todaySchedule.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DashboardCard(
                          title: 'Today\'s Schedule',
                          onTap: () => _navigateTo(const DailyScheduleScreen()),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 20),
                          child: Column(
                            children: [
                              ..._buildSchedulePreview(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  if (_latestMessages.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DashboardCard(
                          title: 'Recent Messages',
                          onTap: () => _navigateTo(const MessagesScreen()),
                          trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 20),
                          child: Column(
                            children: [
                              ..._buildMessagesPreview(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  if (_ecoPoints > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DashboardCard(
                          title: 'Eco Points',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.eco,
                                  color: AppTheme.accentGreen,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_ecoPoints points earned',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Keep contributing to sustainability',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSchedulePreview() {
    final items = _todaySchedule.take(3).toList();
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isLast = index == items.length - 1;
      
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              DateFormat('HH:mm').format(item.startAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildMessagesPreview() {
    final messages = _latestMessages.take(3).toList();
    return messages.asMap().entries.map((entry) {
      final index = entry.key;
      final msg = entry.value;
      final isLast = index == messages.length - 1;
      
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 8),
            if (!msg.isRead) const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: msg.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                  fontWeight: msg.isRead ? FontWeight.normal : FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDateInfo(String label, String date, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }
}