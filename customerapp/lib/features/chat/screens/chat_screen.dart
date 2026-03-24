import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/chat/providers/chat_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String otherPartyName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherPartyName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = LocalStorage.getString('user_id') ?? '';
    Future.microtask(() {
      final notifier = ref.read(chatProvider.notifier);
      notifier.fetchMessages(widget.roomId);
      notifier.subscribeToRoom(widget.roomId);
      notifier.markAsRead(widget.roomId);
    });
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).disposeChannel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(widget.roomId, text);
    _messageController.clear();
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherPartyName)),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? const Center(child: Text('No messages yet. Say hello!', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == _userId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primaryGreen : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(msg.message,
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('hh:mm a').format(msg.createdAt),
                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
