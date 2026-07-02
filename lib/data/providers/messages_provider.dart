import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/message.dart';
import '../providers/auth_provider.dart';

final messagesProvider = StreamProvider<List<Message>>((ref) {
  final guestId = ref.watch(authStateProvider.select((s) => s.guest?.id));
  if (guestId == null) return Stream.value([]);

  return Supabase.instance.client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('guest_id', guestId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map((e) => Message.fromJson(e)).toList());
});

final messagesControllerProvider = Provider<MessagesController>((ref) {
  return MessagesController(ref);
});

class MessagesController {
  final Ref _ref;

  MessagesController(this._ref);

  Future<bool> sendMessage(String content) async {
    final guestId = _ref.read(authStateProvider).guest?.id;
    if (guestId == null) return false;

    try {
      await Supabase.instance.client.from('messages').insert({
        'guest_id': guestId,
        'sender_type': 'guest',
        'content': content.trim(),
        'is_read': false,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('sendMessage error: $e');
      return false;
    }
  }
}
