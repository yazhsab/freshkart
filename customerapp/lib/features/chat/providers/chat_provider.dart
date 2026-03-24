import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/chat_models.dart';

class ChatState {
  final bool isLoading;
  final List<ChatRoomModel> rooms;
  final List<ChatMessageModel> messages;
  final String? error;

  ChatState({this.isLoading = false, this.rooms = const [], this.messages = const [], this.error});

  ChatState copyWith({bool? isLoading, List<ChatRoomModel>? rooms, List<ChatMessageModel>? messages, String? error}) =>
    ChatState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      messages: messages ?? this.messages,
      error: error,
    );
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState());

  final _api = ApiClient.instance;
  RealtimeChannel? _channel;

  Future<void> fetchRooms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/api/v1/chat/rooms');
      final rooms = (response.data['data'] as List)
          .map((e) => ChatRoomModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, rooms: rooms);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ChatRoomModel?> createOrGetRoom({
    String? orderId,
    String? bookingId,
    required String otherPartyId,
    required String otherPartyType,
  }) async {
    try {
      final response = await _api.post('/api/v1/chat/rooms', data: {
        'order_id': orderId,
        'booking_id': bookingId,
        'other_party_id': otherPartyId,
        'other_party_type': otherPartyType,
      });
      return ChatRoomModel.fromJson(response.data['data']);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> fetchMessages(String roomId, {int page = 1}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get('/api/v1/chat/rooms/$roomId/messages?page=$page&limit=50');
      final messages = (response.data['data'] as List)
          .map((e) => ChatMessageModel.fromJson(e))
          .toList();
      state = state.copyWith(
        isLoading: false,
        messages: page == 1 ? messages.reversed.toList() : [...messages.reversed, ...state.messages],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String roomId, String message) async {
    try {
      await _api.post('/api/v1/chat/rooms/$roomId/messages', data: {
        'message': message,
        'message_type': 'text',
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void subscribeToRoom(String roomId) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('chat:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (payload) {
            final newMsg = ChatMessageModel.fromJson(payload.newRecord);
            state = state.copyWith(messages: [...state.messages, newMsg]);
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String roomId) async {
    try {
      await _api.patch('/api/v1/chat/rooms/$roomId/read');
    } catch (_) {}
  }

  void disposeChannel() {
    _channel?.unsubscribe();
    _channel = null;
  }

  @override
  void dispose() {
    disposeChannel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
