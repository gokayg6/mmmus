/// OmeChat Message Model
class Message {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final bool isMe;
  final MessageStatus status;
  
  const Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    required this.isMe,
    this.status = MessageStatus.sent,
  });
  
  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    DateTime? timestamp,
    bool? isMe,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
