/// Message model (aligned with backend)
class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  
  // UI helpers
  final bool isMe; // Calculated based on current user ID

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.isMe = false,
  });

  factory Message.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'],
      isMe: currentUserId != null ? json['sender_id'] == currentUserId : false,
    );
  }
}

/// Conversation model for chat list
class Conversation {
  final String id; // Friend ID usually, or Friendship ID? Backend returns friend details
  final String otherUserId; // NEW FIELD
  final String otherUsername;
  final String? otherAvatarUrl;
  final String lastMessage;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isOnline;

  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatarUrl,
    required this.lastMessage,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final friend = json['friend'];
    final lastMsg = json['last_message'];
    
    return Conversation(
      id: friend['id'],
      otherUserId: friend['id'], // Assuming friend.id is the user ID
      otherUsername: friend['username'],
      otherAvatarUrl: friend['avatar_url'],
      lastMessage: lastMsg != null ? lastMsg['content'] : '',
      lastActivity: lastMsg != null ? DateTime.parse(lastMsg['created_at']) : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      isOnline: friend['is_online'] ?? false,
    );
  }

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
