import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:freshkart_worker/core/api/api_client.dart';
import 'package:freshkart_worker/core/models/chat_models.dart';

// Chat rooms provider
final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoomModel>>>(
  (ref) => ChatRoomsNotifier(ref),
);

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoomModel>>> {
  final Ref _ref;

  ChatRoomsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchChatRooms();
  }

  Future<void> fetchChatRooms() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/api/chat/rooms');
      final rooms = (response.data['data'] as List)
          .map((json) => ChatRoomModel.fromJson(json))
          .toList();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Chat messages provider
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    AsyncValue<List<ChatMessageModel>>, String>(
  (ref, roomId) => ChatMessagesNotifier(ref, roomId),
);

class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessageModel>>> {
  final Ref _ref;
  final String roomId;
  StreamSubscription? _subscription;

  ChatMessagesNotifier(this._ref, this.roomId)
      : super(const AsyncValue.loading()) {
    fetchMessages();
    _subscribeToMessages();
  }

  Future<void> fetchMessages() async {
    try {
      state = const AsyncValue.loading();
      final apiClient = _ref.read(apiClientProvider);
      final response =
          await apiClient.get('/api/chat/rooms/$roomId/messages');
      final messages = (response.data['data'] as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    final supabase = Supabase.instance.client;
    _subscription = supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .listen((data) {
          final messages =
              data.map((json) => ChatMessageModel.fromJson(json)).toList();
          if (mounted) {
            state = AsyncValue.data(messages);
          }
        });
  }

  Future<void> sendMessage(String message,
      {String messageType = 'text'}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post(
        '/api/chat/rooms/$roomId/messages',
        data: {
          'message': message,
          'message_type': messageType,
        },
      );
    } catch (e) {
      // Handle send error
    }
  }

  Future<void> markAsRead() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post('/api/chat/rooms/$roomId/read');
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
