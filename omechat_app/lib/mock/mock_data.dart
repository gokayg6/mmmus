import '../models/user.dart';
import '../domain/models/chat_models.dart';
import '../models/call.dart';

/// Conversation model for mock data (simplified)
class MockConversation {
  final String id;
  final User user;
  final Message lastMessage;
  final int unreadCount;
  final DateTime lastActivity;
  
  const MockConversation({
    required this.id,
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastActivity,
  });
}

/// Mock Data for OmeChat UI
class MockData {
  // === USERS ===
  static final List<User> users = [
    User(
      id: '1',
      name: 'Emma Wilson',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    User(
      id: '2', 
      name: 'Alex Chen',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    User(
      id: '3',
      name: 'Sofia Rodriguez',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    User(
      id: '4',
      name: 'James Miller',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    ),
    User(
      id: '5',
      name: 'Olivia Brown',
      isOnline: true,
      lastSeen: DateTime.now(),
    ),
    User(
      id: '6',
      name: 'Lucas Garcia',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
  
  // === MESSAGES ===
  static final List<Message> sampleConversation = [
    Message(
      id: 'm1',
      content: 'Hey! How are you doing? 👋',
      senderId: '1',
      receiverId: 'me',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      isRead: true,
      isMe: false,
    ),
    Message(
      id: 'm2',
      content: 'Hi! I\'m doing great, thanks for asking! What about you?',
      senderId: 'me',
      receiverId: '1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 43)),
      isRead: true,
      isMe: true,
    ),
    Message(
      id: 'm3',
      content: 'Pretty good! Just finished work. Want to grab coffee sometime this week?',
      senderId: '1',
      receiverId: 'me',
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
      isRead: true,
      isMe: false,
    ),
    Message(
      id: 'm4',
      content: 'That sounds amazing! I\'m free on Thursday afternoon, does that work for you?',
      senderId: 'me',
      receiverId: '1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
      isRead: true,
      isMe: true,
    ),
    Message(
      id: 'm5',
      content: 'Perfect! Thursday at 3pm? There\'s this new cafe downtown I\'ve been wanting to try.',
      senderId: '1',
      receiverId: 'me',
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      isRead: true,
      isMe: false,
    ),
    Message(
      id: 'm6',
      content: 'Sounds perfect! Send me the location 📍',
      senderId: 'me',
      receiverId: '1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 33)),
      isRead: true,
      isMe: true,
    ),
    Message(
      id: 'm7',
      content: 'Will do! It\'s called "The Orange Bean" - you\'ll love it! ☕',
      senderId: '1',
      receiverId: 'me',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: true,
      isMe: false,
    ),
    Message(
      id: 'm8',
      content: 'Can\'t wait! See you then! 😊',
      senderId: 'me',
      receiverId: '1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
      isRead: true,
      isMe: true,
    ),
  ];
  
  // === CONVERSATIONS ===
  static final List<MockConversation> conversations = [
    MockConversation(
      id: 'c1',
      user: users[0],
      lastMessage: sampleConversation.last,
      unreadCount: 2,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 28)),
    ),
    MockConversation(
      id: 'c2',
      user: users[1],
      lastMessage: Message(
        id: 'cm2',
        content: 'That was such a fun game!',
        senderId: '2',
        receiverId: 'me',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
        isMe: false,
      ),
      unreadCount: 0,
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    MockConversation(
      id: 'c3',
      user: users[2],
      lastMessage: Message(
        id: 'cm3',
        content: 'See you tomorrow!',
        senderId: 'me',
        receiverId: '3',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        isMe: true,
      ),
      unreadCount: 0,
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MockConversation(
      id: 'c4',
      user: users[3],
      lastMessage: Message(
        id: 'cm4',
        content: 'Thanks for the help! 🙏',
        senderId: '4',
        receiverId: 'me',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
        isMe: false,
      ),
      unreadCount: 1,
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MockConversation(
      id: 'c5',
      user: users[4],
      lastMessage: Message(
        id: 'cm5',
        content: 'Haha that\'s hilarious! 😂',
        senderId: '5',
        receiverId: 'me',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        isMe: false,
      ),
      unreadCount: 0,
      lastActivity: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
  
  // === CALLS ===
  static final List<Call> calls = [
    Call(
      id: 'call1',
      user: users[0],
      type: CallType.video,
      direction: CallDirection.incoming,
      status: CallStatus.answered,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      duration: const Duration(minutes: 15, seconds: 32),
    ),
    Call(
      id: 'call2',
      user: users[1],
      type: CallType.voice,
      direction: CallDirection.outgoing,
      status: CallStatus.answered,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      duration: const Duration(minutes: 8, seconds: 45),
    ),
    Call(
      id: 'call3',
      user: users[2],
      type: CallType.video,
      direction: CallDirection.incoming,
      status: CallStatus.missed,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Call(
      id: 'call4',
      user: users[3],
      type: CallType.voice,
      direction: CallDirection.outgoing,
      status: CallStatus.declined,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Call(
      id: 'call5',
      user: users[4],
      type: CallType.video,
      direction: CallDirection.incoming,
      status: CallStatus.answered,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      duration: const Duration(minutes: 25, seconds: 10),
    ),
  ];
  
  /// Get messages for a specific conversation
  static List<Message> getMessagesForConversation(String conversationId) {
    if (conversationId == 'c1') {
      return sampleConversation;
    }
    // Return sample messages for other conversations
    return [
      Message(
        id: 'sample1',
        content: 'Hey there!',
        senderId: 'other',
        receiverId: 'me',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
        isMe: false,
      ),
      Message(
        id: 'sample2',
        content: 'Hi! How are you?',
        senderId: 'me',
        receiverId: 'other',
        createdAt: DateTime.now().subtract(const Duration(minutes: 55)),
        isRead: true,
        isMe: true,
      ),
    ];
  }
}
