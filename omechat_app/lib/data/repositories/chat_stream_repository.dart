/// Chat Stream Repository - Real-time SQLite Streams
/// 
/// Provides Stream-based access to SQLite data.
/// UI automatically updates when SQLite changes.
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_service.dart';
import '../../domain/models/chat_models.dart';

class ChatStreamRepository {
  final DatabaseService _db;
  
  // Stream controllers for real-time updates
  final Map<String, StreamController<List<Message>>> _messageStreams = {};
  final StreamController<List<Conversation>> _conversationStream = StreamController<List<Conversation>>.broadcast();
  
  ChatStreamRepository(this._db);
  
  /// Get messages stream for a conversation
  /// Automatically updates when SQLite changes
  Stream<List<Message>> watchMessages(String conversationId, String currentUserId) {
    if (!_messageStreams.containsKey(conversationId)) {
      _messageStreams[conversationId] = StreamController<List<Message>>.broadcast();
      _startMessageStream(conversationId, currentUserId);
    }
    return _messageStreams[conversationId]!.stream;
  }
  
  /// Get conversations stream
  Stream<List<Conversation>> watchConversations() {
    _startConversationStream();
    return _conversationStream.stream;
  }
  
  /// Start message stream for a conversation
  void _startMessageStream(String conversationId, String currentUserId) async {
    // Initial load
    await _emitMessages(conversationId, currentUserId);
    
    // Poll for changes (SQLite doesn't have native change notifications)
    // Fast polling for instant UI updates
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_messageStreams.containsKey(conversationId) || _messageStreams[conversationId]!.isClosed) {
        timer.cancel();
        return;
      }
      await _emitMessages(conversationId, currentUserId);
    });
  }
  
  /// Start conversation stream
  void _startConversationStream() async {
    // Initial load
    await _emitConversations();
    
    // Poll for changes
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_conversationStream.isClosed) {
        timer.cancel();
        return;
      }
      await _emitConversations();
    });
  }
  
  /// Emit messages to stream
  Future<void> _emitMessages(String conversationId, String currentUserId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
      );
      
      final messages = rows.map((row) => _messageFromRow(row, currentUserId)).toList();
      
      if (_messageStreams.containsKey(conversationId) && !_messageStreams[conversationId]!.isClosed) {
        _messageStreams[conversationId]!.add(messages);
      }
    } catch (e) {
      // Even on error, emit empty list (never crash)
      if (_messageStreams.containsKey(conversationId) && !_messageStreams[conversationId]!.isClosed) {
        _messageStreams[conversationId]!.add(<Message>[]);
      }
    }
  }
  
  /// Emit conversations to stream
  Future<void> _emitConversations() async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'chats',
        orderBy: 'last_activity DESC',
      );
      
      final conversations = rows.map((row) => _conversationFromRow(row)).toList();
      
      if (!_conversationStream.isClosed) {
        _conversationStream.add(conversations);
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  /// Manually trigger message stream update - IMMEDIATE
  Future<void> refreshMessages(String conversationId, String currentUserId) async {
    // Emit immediately without waiting
    _emitMessages(conversationId, currentUserId);
  }
  
  /// Force immediate emit (for send button)
  Future<void> forceEmitMessages(String conversationId, String currentUserId) async {
    await _emitMessages(conversationId, currentUserId);
  }
  
  /// Manually trigger conversation stream update
  Future<void> refreshConversations() async {
    await _emitConversations();
  }
  
  /// Close all streams
  void dispose() {
    for (final stream in _messageStreams.values) {
      stream.close();
    }
    _messageStreams.clear();
    _conversationStream.close();
  }
  
  Message _messageFromRow(Map<String, dynamic> row, String currentUserId) {
    final senderId = row['sender_id'] as String;
    return Message(
      id: row['id'] as String,
      senderId: senderId,
      receiverId: row['receiver_id'] as String,
      content: row['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      isRead: (row['is_read'] as int) == 1,
      isMe: senderId == currentUserId,
    );
  }
  
  Conversation _conversationFromRow(Map<String, dynamic> row) {
    return Conversation(
      id: row['id'] as String,
      otherUserId: row['id'] as String, // FIX: Added otherUserId
      otherUsername: row['other_username'] as String,
      otherAvatarUrl: row['other_avatar_url'] as String?,
      lastMessage: row['last_message_content'] as String? ?? '',
      lastActivity: DateTime.fromMillisecondsSinceEpoch(row['last_activity'] as int),
      unreadCount: row['unread_count'] as int,
      isOnline: (row['is_online'] as int) == 1,
    );
  }
}
