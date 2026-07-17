import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_sheet.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/reservation_provider.dart';
import '../../../data/providers/messages_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    _textController.clear();

    final success = await ref.read(messagesControllerProvider).sendMessage(content);
    if (!mounted) return;
    setState(() => _sending = false);

    if (success) {
      _scrollToBottom();
    } else {
      _textController.text = content;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final reservationState = ref.watch(reservationProvider);

    if (!authState.isAuthenticated) {
      return GestureDetector(
        onTap: () => showAuthSheet(context, message: 'Sign in to send messages to the hotel.'),
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                    child: const Icon(Icons.chat_outlined, size: 48, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  const Text('Messaging', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Sign in to send messages to hotel staff', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () { Navigator.of(context).pop(); context.push('/login'); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkNavy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!reservationState.hasActiveReservation) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                  child: const Icon(Icons.lock_outline, size: 40, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 20),
                const Text('Messaging is available after booking.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/rooms'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Book a Room'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.darkNavy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ref.watch(messagesProvider).when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lightGray),
                            child: const Icon(Icons.chat_outlined, size: 40, color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: 16),
                          const Text('No messages yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Send a message to hotel staff', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isStaff = msg.senderType != 'guest';
                    return _buildMessageBubble(msg.content, isStaff, _formatTime(msg.createdAt));
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(
                child: Text(
                  'We couldn\'t load your messages. Pull down to try again.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_sending,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppColors.lightGray,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.darkNavy),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _sending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isStaff, String time) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isStaff ? AppColors.lightGray : AppColors.darkNavy,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isStaff ? const Radius.circular(4) : const Radius.circular(20),
              bottomRight: isStaff ? const Radius.circular(20) : const Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(color: isStaff ? AppColors.textPrimary : Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: isStaff ? AppColors.textTertiary : Colors.white.withValues(alpha: 0.7), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inHours < 48) return 'Yesterday ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
