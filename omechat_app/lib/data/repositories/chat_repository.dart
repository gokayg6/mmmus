import '../../domain/models/chat_models.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations();
  
  /// Get messages for a specific conversation
  Future<List<Message>> getMessages(String conversationId);
  
  /// Send a message
  Future<Message> sendMessage(String conversationId, String text);
  
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
      otherUsername: 'Aylin',
      lastMessage: 'Merhaba! Nasılsın?',
      lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      isOnline: true,
    ),
    Conversation(
      id: '2',
      otherUsername: 'Mehmet',
      lastMessage: 'Görüşürüz 👋',
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
    Conversation(
      id: '3',
      otherUsername: 'Zeynep',
      lastMessage: 'Çok güzel bir sohbetti!',
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 1,
      isOnline: true,
    ),
    Conversation(
      id: '4',
      otherUsername: 'Can',
      lastMessage: 'Yarın tekrar konuşalım mı?',
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  final Map<String, List<Message>> _messages = {};

  MockChatRepository() {
    // Initialize with some mock messages
    _messages['1'] = [
      Message(
        id: 'm1',
        senderId: 'user_1',
        receiverId: 'me',
        content: 'Merhaba!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: true,
        isMe: false,
      ),
      Message(
        id: 'm2',
        senderId: 'me',
        receiverId: 'user_1',
        content: 'Selam! Nasılsın?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        isRead: true,
        isMe: true,
      ),
      Message(
        id: 'm3',
        senderId: 'user_1',
        receiverId: 'me',
        content: 'İyiyim, teşekkürler! Sen nasılsın?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        isMe: false,
      ),
    ];
  }

  @override
  Future<List<Conversation>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_conversations);
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _messages[conversationId] ?? [];
  }

  @override
  Future<Message> sendMessage(String conversationId, String text) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      receiverId: conversationId,
      content: text,
      createdAt: DateTime.now(),
      isRead: false,
      isMe: true,
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
