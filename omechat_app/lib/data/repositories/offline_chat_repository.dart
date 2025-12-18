/// Offline-First Chat Repository
/// 
/// SQLite is the single source of truth.
/// NO network operations - 100% local-only for now.
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_service.dart';
import '../../core/network/network_result.dart';
import '../../domain/models/chat_models.dart';
import '../../services/chat_service.dart';

class OfflineChatRepository {
  final DatabaseService _db;
  final ChatService _chatService;
  
  // Single broadcasting stream for database updates
  // We emit 'null' to signal "something changed, please refresh"
  final _updateController = StreamController<void>.broadcast();
  
  OfflineChatRepository(this._db, this._chatService);

  /// Watch messages for a specific conversation
  /// 
  /// This returns a Stream that:
  /// 1. Emits immediately (initial data)
  /// 2. Emits whenever _updateController signals a change
  /// 3. Always reads fresh data from SQLite
  Stream<List<Message>> watchMessages(String conversationId, String currentUserId) {
    // 1. Create a stream that emits 'null' (trigger) immediately, and then whenever updates happen
    return _updateController.stream
        .startWith(null) // Ensure initial load
        .asyncMap((_) => _fetchMessagesFromDb(conversationId, currentUserId));
  }
  
  /// Private helper to read from DB - Logic is identical to old getMessages but returns simple list
  Future<List<Message>> _fetchMessagesFromDb(String conversationId, String currentUserId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
      );
      return rows.map((row) => _messageFromRow(row, currentUserId)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get conversations - Helper for list screens
  Future<NetworkResult<List<Conversation>>> getConversations() async {
    try {
      final db = await _db.database;
      final rows = await db.query('chats', orderBy: 'last_activity DESC');
      final conversations = rows.map((row) => _conversationFromRow(row)).toList();
      return LocalOnly(conversations);
    } catch (e) {
      return LocalOnly(<Conversation>[]);
    }
  }
  
  /// Get messages (Legacy/One-shot)
  Future<NetworkResult<List<Message>>> getMessages(String conversationId, String currentUserId) async {
    final messages = await _fetchMessagesFromDb(conversationId, currentUserId);
    return LocalOnly(messages);
  }

  /// STRICT FLOW:
  /// 1. Insert to SQLite (pending)
  /// 2. FORCE EMIT stream update
  /// 3. (Optional/Later) Trigger API sync
  Future<void> sendMessage(
    String conversationId, 
    String content, 
    String currentUserId, {
    String? receiverName,
    String? receiverAvatar,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final localId = '${now}_${content.hashCode}'; 

    try {
      await db.transaction((txn) async {
        // 1. ENSURE CONVERSATION EXISTS (Fix FK Constraint)
        // If we don't do this, insert into messages fails if chat doesn't exist
        final chatExists = await txn.query(
          'chats',
          where: 'id = ?',
          whereArgs: [conversationId],
        );

        if (chatExists.isEmpty) {
          await txn.insert(
            'chats',
            {
              'id': conversationId,
              'other_username': receiverName ?? 'User', // Fix: Use actual name
              'other_avatar_url': receiverAvatar,
              'last_message_content': content,
              'last_activity': now,
              'unread_count': 0, // Sending my own message, so 0 unread
              'is_online': 0,
              'sync_status': 'synced', // Local chat container is "synced" enough for now
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } else {
             // Update existing chat preview
            await txn.update(
            'chats',
            {
                'last_message_content': content,
                'last_activity': now,
                'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [conversationId],
            );
        }

        // 2. INSERT MESSAGE
        await txn.insert(
          'messages',
          {
            'id': localId, // Using localId as PK temporarily
            'conversation_id': conversationId,
            'sender_id': currentUserId,
            'receiver_id': conversationId, // Assuming 1-1
            'content': content,
            'created_at': now,
            'is_read': 0,
            'sync_status': 'pending', 
            'local_id': localId,
            'updated_at': now,
            'server_id': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      // 3. EMIT UPDATE - This triggers the StreamBuilder in UI
      print('OFFLINE_REPO: Message inserted with ID $localId. Emitting update.');
      _updateController.add(null); 
      
      // 4. FIRE-AND-FORGET SYNC
      // We do not await this to keep UI responsive, but we handle the result to update status
      _syncMessageToBackend(localId, conversationId, content, currentUserId);

    } catch (e) {
      print('OFFLINE_REPO ERROR: Insert failed: $e');
      // Rethrow so UI can show error snackbar
      rethrow;
    }
  }

  /// Background sync task
  Future<void> _syncMessageToBackend(String localId, String receiverId, String content, String senderId) async {
    try {
      print('OFFLINE_REPO: Syncing message $localId to backend...');
      final sentMessage = await _chatService.sendMessage(receiverId, content);
      
      // Update DB with server ID and synced status
      final db = await _db.database;
      await db.update(
        'messages',
        {
          'sync_status': 'synced',
          'server_id': sentMessage.id,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [localId],
      );
      
      print('OFFLINE_REPO: Message $localId synced successfully. Server ID: ${sentMessage.id}');
      // Emit again to show checkmarks
      _updateController.add(null);
      
    } catch (e) {
      print('OFFLINE_REPO: Sync failed for $localId: $e');
      // Update status to failed
      try {
        final db = await _db.database;
        await db.update(
          'messages',
          {
            'sync_status': 'failed',
          },
          where: 'id = ?',
          whereArgs: [localId],
        );
        _updateController.add(null);
      } catch (e2) {
        print('OFFLINE_REPO: Failed to update sync status: $e2');
      }
    }
  }
  
  // ============================================
  // HELPERS
  // ============================================
  
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
  
  Future<void> _updateConversationLastMessage(String conversationId, String content, int timestamp) async {
    try {
      final db = await _db.database;
      await db.update(
        'chats',
        {
          'last_message_content': content,
          'last_activity': timestamp,
          'updated_at': timestamp,
        },
        where: 'id = ?',
        whereArgs: [conversationId],
      );
    } catch (e) {
      // Silent fail
    }
  }
  
  Future<void> saveConversationFromNetwork(Conversation conv) async {}
  Future<void> saveMessageFromNetwork(Message msg, String conversationId) async {}
  Future<void> updateMessageSyncStatus(String localId, String remoteId, bool isSynced) async {}
}

// Extension to support startWith on Stream (RxDart style without RxDart)
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initial) async* {
    yield initial;
    yield* this;
  }
}
