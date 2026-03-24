import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:freshkart_worker/core/models/chat_models.dart';
import 'package:freshkart_worker/features/chat/providers/chat_provider.dart';
import 'package:freshkart_worker/features/chat/screens/chat_screen.dart';

class ChatRoomsScreen extends ConsumerWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: chatRoomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(chatRoomsProvider.notifier).fetchChatRooms(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(chatRoomsProvider.notifier).fetchChatRooms(),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = rooms[index];
                return _ChatRoomTile(room: room);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;
  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: room.customerAvatar != null
            ? CachedNetworkImageProvider(room.customerAvatar!)
            : null,
        child: room.customerAvatar == null
            ? Text(
                (room.customerName ?? 'C')[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        room.customerName ?? 'Customer',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: room.bookingId != null
          ? Text('Booking #${room.bookingId!.substring(0, 8)}')
          : null,
      trailing: room.lastMessageAt != null
          ? Text(
              timeago.format(room.lastMessageAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: room.id,
              customerName: room.customerName ?? 'Customer',
            ),
          ),
        );
      },
    );
  }
}
