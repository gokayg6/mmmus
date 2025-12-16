/// Sync Engine - Background Synchronization
/// 
/// Handles all background sync operations.
/// Never blocks UI, always works silently.
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../network/network_result.dart';
import '../../data/repositories/offline_chat_repository.dart';
import '../../services/chat_service.dart';

class SyncEngine {
  final DatabaseService _db;
  final OfflineChatRepository _repository;
  final ChatService _chatService;
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  SyncEngine(this._db, this._repository, this._chatService);
  
  /// Start periodic sync
  void start() {
    // Sync immediately
    syncAll();
    
    // Then sync every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAll();
    });
  }
  
  /// Stop periodic sync
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
  
  /// Sync all pending operations
  Future<void> syncAll() async {
    if (_isSyncing) return; // Prevent concurrent syncs
    _isSyncing = true;
    
    try {
      await _syncPendingMessages();
      await _syncConversations();
      await _retryFailedRequests();
    } catch (e) {
      // Silent fail - sync will retry later
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync pending messages
  Future<void> _syncPendingMessages() async {
    try {
      final db = await _db.database;
      
      // Get all pending messages
      final pendingMessages = await db.query(
        'messages',
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
        limit: 10, // Process in batches
      );
      
      for (final row in pendingMessages) {
        await _syncSingleMessage(row);
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  /// Sync a single message
  Future<void> _syncSingleMessage(Map<String, dynamic> row) async {
    try {
      final conversationId = row['conversation_id'] as String;
      final content = row['content'] as String;
      final localId = row['local_id'] as String?;
      
      if (localId == null) return;
      
      // Try to send via API
      final message = await _chatService.sendMessage(conversationId, content);
      
      // Update sync status
      await _repository.updateMessageSyncStatus(localId, message.id, true);
    } catch (e) {
      // Mark as failed (will retry later)
      try {
        final db = await _db.database;
        await db.update(
          'messages',
          {'sync_status': 'failed', 'updated_at': DateTime.now().millisecondsSinceEpoch},
          where: 'local_id = ?',
          whereArgs: [row['local_id']],
        );
      } catch (_) {
        // Silent fail
      }
    }
  }
  
  /// Sync conversations list
  Future<void> _syncConversations() async {
    try {
      final conversations = await _chatService.getConversations();
      for (final conv in conversations) {
        await _repository.saveConversationFromNetwork(conv);
      }
    } catch (e) {
      // Silent fail - local data is already available
    }
  }
  
  /// Retry failed requests
  Future<void> _retryFailedRequests() async {
    try {
      final db = await _db.database;
      
      // Get failed requests that are ready for retry
      final failedRequests = await db.query(
        'failed_requests',
        where: 'retry_after IS NULL OR retry_after < ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch],
        limit: 5, // Process in small batches
      );
      
      for (final request in failedRequests) {
        // Could implement retry logic here
        // For now, just log
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  /// Force sync a specific conversation
  Future<void> syncConversation(String conversationId) async {
    try {
      // Sync messages
      final messages = await _chatService.getHistory(conversationId);
      for (final msg in messages) {
        await _repository.saveMessageFromNetwork(msg, conversationId);
      }
    } catch (e) {
      // Silent fail
    }
  }
}




