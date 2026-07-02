import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/notification.dart';
import '../providers/auth_provider.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final guestId = ref.watch(authStateProvider.select((s) => s.guest?.id));
  if (guestId == null) return Stream.value([]);

  final guestIdStr = guestId;
  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('guest_id', guestIdStr)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((e) => AppNotification.fromJson(e)).toList());
});
