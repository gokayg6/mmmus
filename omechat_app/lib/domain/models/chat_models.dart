/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus { sending, sent, delivered, read, failed }

/// Conversation model for chat list
class Conversation {
  final String id;
  final String oderId;
  final String otherUsername;
  final String? otherAvatarUrl;
  final String lastMessage;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isOnline;

  const Conversation({
    required this.id,
    required this.oderId,
    required this.otherUsername,
    this.otherAvatarUrl,
    required this.lastMessage,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  bool get hasUnread => unreadCount > 0;

  String get initials {
    if (otherUsername.isEmpty) return '?';
    final parts = otherUsername.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return otherUsername.substring(0, otherUsername.length >= 2 ? 2 : 1).toUpperCase();
  }
}
