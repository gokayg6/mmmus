import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../domain/models/chat_models.dart';

/// Chat Service for API interactions
class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  /// Send a message
  Future<Message> sendMessage(String receiverId, String content) async {
    final response = await _apiClient.dio.post(
      '/api/v1/chat/send',
      data: {
        'receiver_id': receiverId,
        'content': content,
      },
    );
    return Message.fromJson(response.data);
  }

  /// Get chat history
  Future<List<Message>> getHistory(String otherUserId) async {
    final response = await _apiClient.dio.get('/api/v1/chat/history/$otherUserId');
    return (response.data as List).map((e) => Message.fromJson(e)).toList();
  }

  /// Get conversations
  Future<List<Conversation>> getConversations() async {
    final response = await _apiClient.dio.get('/api/v1/chat/conversations');
    return (response.data as List).map((e) => Conversation.fromJson(e)).toList();
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});
