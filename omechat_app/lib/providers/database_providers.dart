/// Database and Repository Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_service.dart';
import '../data/repositories/offline_chat_repository.dart';
import '../data/repositories/chat_stream_repository.dart';
import '../core/sync/sync_engine.dart';
import '../services/chat_service.dart';

/// Database Service Provider (singleton)
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Offline Chat Repository Provider (Local-only, no backend)
final offlineChatRepositoryProvider = Provider<OfflineChatRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final chatService = ref.watch(chatServiceProvider);
  return OfflineChatRepository(db, chatService);
});

/// Chat Stream Repository Provider (singleton)
final chatStreamRepositoryProvider = Provider<ChatStreamRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final repository = ChatStreamRepository(db);
  
  // Cleanup on dispose
  ref.onDispose(() {
    repository.dispose();
  });
  
  return repository;
});

/// Sync Engine Provider (singleton, auto-starts)
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final repository = ref.watch(offlineChatRepositoryProvider);
  final chatService = ref.watch(chatServiceProvider);
  
  final engine = SyncEngine(db, repository, chatService);
  
  // Auto-start sync engine
  engine.start();
  
  // Cleanup on dispose
  ref.onDispose(() {
    engine.stop();
  });
  
  return engine;
});

