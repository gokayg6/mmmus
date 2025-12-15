/// SQLite Database Service - Single Source of Truth
/// 
/// This service manages all local database operations.
/// It is the foundation of our offline-first architecture.
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseService {
  static const String _databaseName = 'omechat.db';
  static const int _databaseVersion = 1;
  
  Database? _database;
  static DatabaseService? _instance;
  
  DatabaseService._();
  
  factory DatabaseService() {
    _instance ??= DatabaseService._();
    return _instance!;
  }
  
  /// Get database instance (initializes if needed)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }
  
  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chats (
        id TEXT PRIMARY KEY,
        other_user_id TEXT NOT NULL,
        other_username TEXT NOT NULL,
        other_avatar_url TEXT,
        last_message_id TEXT,
        last_message_content TEXT,
        last_activity INTEGER NOT NULL,
        unread_count INTEGER NOT NULL DEFAULT 0,
        is_online INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        server_id TEXT,
        local_id TEXT UNIQUE,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES chats(id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT,
        avatar_url TEXT,
        is_online INTEGER NOT NULL DEFAULT 0,
        last_seen INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        max_retries INTEGER NOT NULL DEFAULT 3,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    
    await db.execute('''
      CREATE TABLE failed_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT,
        error_code INTEGER,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        retry_after INTEGER
      )
    ''');
    
    // Create indexes for performance
    await db.execute('CREATE INDEX idx_messages_conversation ON messages(conversation_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON messages(created_at)');
    await db.execute('CREATE INDEX idx_messages_sync_status ON messages(sync_status)');
    await db.execute('CREATE INDEX idx_chats_last_activity ON chats(last_activity)');
    await db.execute('CREATE INDEX idx_chats_sync_status ON chats(sync_status)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(status)');
    await db.execute('CREATE INDEX idx_sync_queue_entity ON sync_queue(entity_type, entity_id)');
    await db.execute('CREATE UNIQUE INDEX idx_messages_local_id ON messages(local_id)');
  }
  
  /// Handle database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will go here
    // For now, we're at version 1
  }
  
  /// Post-open operations
  Future<void> _onOpen(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  /// Close database connection
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
  
  /// Clear all data (for testing/logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chats');
    await db.delete('users');
    await db.delete('sync_queue');
    await db.delete('failed_requests');
  }
}

