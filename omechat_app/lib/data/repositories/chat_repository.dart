import '../../domain/models/chat_models.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations();
  
  /// Get messages for a specific conversation
  Future<List<ChatMessage>> getMessages(String conversationId);
  
  /// Send a message
  Future<ChatMessage> sendMessage(String conversationId, String text);
  
  /// Mark conversation as read
  Future<void> markAsRead(String conversationId);
  
  /// Start a new random chat
  Future<Conversation?> startRandomChat();
  
  /// End current chat
  Future<void> endChat(String conversationId);
}

/// Mock implementation of ChatRepository
class MockChatRepository implements ChatRepository {
  final List<Conversation> _conversations = [
    Conversation(
      id: '1',
      oderId: 'user_1',
      otherUsername: 'Aylin',
      lastMessage: 'Merhaba! Nasılsın?',
      lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      isOnline: true,
    ),
    Conversation(
      id: '2',
      oderId: 'user_2',
      otherUsername: 'Mehmet',
      lastMessage: 'Görüşürüz 👋',
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
    Conversation(
      id: '3',
      oderId: 'user_3',
      otherUsername: 'Zeynep',
      lastMessage: 'Çok güzel bir sohbetti!',
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 1,
      isOnline: true,
    ),
    Conversation(
      id: '4',
      oderId: 'user_4',
      otherUsername: 'Can',
      lastMessage: 'Yarın tekrar konuşalım mı?',
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  final Map<String, List<ChatMessage>> _messages = {
    '1': [
      ChatMessage(
        id: 'm1',
        conversationId: '1',
        senderId: 'user_1',
        text: 'Merhaba!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isMe: false,
      ),
      ChatMessage(
        id: 'm2',
        conversationId: '1',
        senderId: 'me',
        text: 'Selam! Nasılsın?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isMe: true,
      ),
      ChatMessage(
        id: 'm3',
        conversationId: '1',
        senderId: 'user_1',
        text: 'İyiyim, teşekkürler! Sen nasılsın?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isMe: false,
      ),
    ],
  };

  @override
  Future<List<Conversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_conversations);
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _messages[conversationId] ?? [];
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      status: MessageStatus.sent,
    );
    
    _messages.putIfAbsent(conversationId, () => []);
    _messages[conversationId]!.add(message);
    
    return message;
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = Conversation(
        id: _conversations[index].id,
        oderId: _conversations[index].oderId,
        otherUsername: _conversations[index].otherUsername,
        otherAvatarUrl: _conversations[index].otherAvatarUrl,
        lastMessage: _conversations[index].lastMessage,
        lastActivity: _conversations[index].lastActivity,
        unreadCount: 0,
        isOnline: _conversations[index].isOnline,
      );
    }
  }

  @override
  Future<Conversation?> startRandomChat() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate searching
    return Conversation(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      oderId: 'random_user',
      otherUsername: 'Anonim Kullanıcı',
      lastMessage: '',
      lastActivity: DateTime.now(),
      unreadCount: 0,
      isOnline: true,
    );
  }

  @override
  Future<void> endChat(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
