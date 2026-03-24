import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_customer/features/chat/providers/chat_provider.dart';
import 'package:freshkart_customer/features/chat/screens/chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatRoomsScreen extends ConsumerStatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  ConsumerState<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends ConsumerState<ChatRoomsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchRooms());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.rooms.isEmpty
              ? const Center(child: Text('No chats yet'))
              : ListView.builder(
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          room.otherPartyType == 'vendor' ? Icons.store :
                          room.otherPartyType == 'delivery_agent' ? Icons.delivery_dining :
                          Icons.handyman,
                        ),
                      ),
                      title: Text(room.otherPartyName ?? room.otherPartyType),
                      subtitle: Text(
                        room.lastMessageAt != null
                            ? timeago.format(room.lastMessageAt!)
                            : 'No messages',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            roomId: room.id,
                            otherPartyName: room.otherPartyName ?? room.otherPartyType,
                          ),
                        ));
                      },
                    );
                  },
                ),
    );
  }
}
