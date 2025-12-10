import 'user.dart';
import 'message.dart';

/// OmeChat Conversation Model
class Conversation {
  final String id;
  final User user;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime lastActivity;
  final bool isPinned;
  final bool isMuted;
  
  const Conversation({
    required this.id,
    required this.user,
    this.lastMessage,
    this.unreadCount = 0,
    required this.lastActivity,
    this.isPinned = false,
    this.isMuted = false,
  });
  
  /// Get preview text for list display
  String get preview {
    if (lastMessage == null) return 'No messages yet';
    final prefix = lastMessage!.isMe ? 'You: ' : '';
    final content = lastMessage!.content;
    if (content.length > 40) {
      return '$prefix${content.substring(0, 40)}...';
    }
    return '$prefix$content';
  }
  
  /// Check if conversation has unread messages
  bool get hasUnread => unreadCount > 0;
  
  Conversation copyWith({
    String? id,
    User? user,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastActivity,
    bool? isPinned,
    bool? isMuted,
  }) {
    return Conversation(
      id: id ?? this.id,
      user: user ?? this.user,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivity: lastActivity ?? this.lastActivity,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
