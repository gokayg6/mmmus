# OmeChat - Offline-First Architecture

## 🎯 Core Principle

**SQLite is the single source of truth. Network is optional.**

The app NEVER waits for API calls. All UI operations read from and write to SQLite instantly. Network synchronization happens silently in the background.

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         UI LAYER                            │
│  (ChatDetailScreen, ChatListScreen, etc.)                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ Reads/Writes
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    SQLite DATABASE                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                │
│  │  chats   │  │ messages  │  │  users   │                │
│  └──────────┘  └──────────┘  └──────────┘                │
│  ┌──────────┐  ┌──────────┐                               │
│  │sync_queue│  │failed_req│                               │
│  └──────────┘  └──────────┘                               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ Background Sync
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   SYNC ENGINE                               │
│  - Processes sync_queue                                     │
│  - Retries failed requests                                  │
│  - Updates SQLite with server data                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ API Calls
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              PRODUCTION DIO INTERCEPTOR                      │
│  - Request fingerprinting (deduplication)                   │
│  - Smart retry with exponential backoff                      │
│  - Circuit breaker pattern                                  │
│  - Permission error classification                          │
│  - NEVER throws raw exceptions                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            │ HTTP Requests
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND API                              │
│  (May be down, slow, or return errors)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ SQLite Schema

### `chats` Table
```sql
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
  sync_status TEXT NOT NULL DEFAULT 'synced',  -- 'synced', 'pending', 'failed'
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### `messages` Table
```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  receiver_id TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  is_read INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'synced',  -- 'synced', 'pending', 'failed'
  server_id TEXT,                               -- Server-assigned ID after sync
  local_id TEXT UNIQUE,                         -- Local ID before sync (for deduplication)
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (conversation_id) REFERENCES chats(id) ON DELETE CASCADE
);
```

### `users` Table
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  is_online INTEGER NOT NULL DEFAULT 0,
  last_seen INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### `sync_queue` Table
```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_type TEXT NOT NULL,      -- 'send_message', 'mark_read', etc.
  entity_type TEXT NOT NULL,          -- 'message', 'conversation', etc.
  entity_id TEXT NOT NULL,
  payload TEXT NOT NULL,              -- JSON payload
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 3,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'  -- 'pending', 'processing', 'completed', 'failed'
);
```

### `failed_requests` Table
```sql
CREATE TABLE failed_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  payload TEXT,
  error_code INTEGER,
  error_message TEXT,
  created_at INTEGER NOT NULL,
  retry_after INTEGER
);
```

### Indexes
- `idx_messages_conversation` on `messages(conversation_id)`
- `idx_messages_created_at` on `messages(created_at)`
- `idx_messages_sync_status` on `messages(sync_status)`
- `idx_chats_last_activity` on `chats(last_activity)`
- `idx_chats_sync_status` on `chats(sync_status)`
- `idx_sync_queue_status` on `sync_queue(status)`
- `idx_sync_queue_entity` on `sync_queue(entity_type, entity_id)`
- `idx_messages_local_id` UNIQUE on `messages(local_id)`

---

## 🔄 Data Flow

### Reading Messages (Chat Screen Opens)

1. **UI calls** `ChatController._loadMessages()`
2. **Repository** reads from SQLite instantly (always succeeds)
3. **UI displays** messages immediately (no loading spinner)
4. **Background**: Sync engine attempts to fetch latest from server
5. **If sync succeeds**: SQLite is updated, UI automatically refreshes
6. **If sync fails**: UI continues showing cached data (no error shown)

### Sending Message

1. **User types** message and hits send
2. **Repository** writes to SQLite instantly with `sync_status = 'pending'`
3. **UI shows** message immediately (optimistic update)
4. **Background**: Sync engine sends message to server
5. **If sync succeeds**: Message `sync_status` updated to `'synced'`, `server_id` assigned
6. **If sync fails**: Message remains with `sync_status = 'failed'`, will retry later

### Network Errors

All network errors are classified into typed results:

- **`LocalOnly<T>`**: Data exists only locally (offline mode)
- **`Synced<T>`**: Data successfully synced with server
- **`PendingSync<T>`**: Data is pending sync
- **`PermissionDenied`**: 401, 403, 409, 410 errors (user action required)
- **`ServerUnavailable`**: 500, 503, network errors (retryable)

**NEVER** are raw exceptions thrown to UI. All errors are wrapped in typed results.

---

## 🛡️ Error Handling Strategy

### Permission Errors (401, 403, 409, 410)

**NEVER** treated as 500/503. Correctly classified:

- **401 Unauthorized**: "Please log in again"
- **403 Forbidden**: "You do not have permission"
- **409 Conflict**: "Chat room already closed"
- **410 Gone**: "Chat expired or ended"

**UI Behavior**:
- Show friendly message
- Update SQLite state
- Auto-recover or gracefully exit chat

### Server Errors (500, 503)

**UI Behavior**:
- Continue showing cached data
- Show subtle "Offline" indicator
- Retry in background automatically
- Never block user interaction

### Network Errors (Timeout, No Connection)

**UI Behavior**:
- Show cached data immediately
- Display "Offline" indicator
- Auto-retry when connection restored
- Never show error screen

---

## 🔧 Key Components

### 1. DatabaseService
- Singleton SQLite database manager
- Handles migrations
- Provides database instance

### 2. OfflineChatRepository
- All operations read/write SQLite first
- Network operations happen in background
- Returns `NetworkResult<T>` types

### 3. SyncEngine
- Background synchronization
- Processes `sync_queue` table
- Retries failed operations
- Updates SQLite with server data

### 4. ProductionDioInterceptor
- Request fingerprinting (prevents duplicates)
- Smart retry with exponential backoff
- Circuit breaker pattern
- Permission error classification
- Never throws raw exceptions

### 5. NetworkResult Types
- `Synced<T>`: Successfully synced
- `LocalOnly<T>`: Offline data
- `PendingSync<T>`: Pending sync
- `PermissionDenied`: Auth/permission errors
- `ServerUnavailable`: Server/network errors

---

## ✅ Guarantees

### ✅ Chat Screen ALWAYS Opens Instantly
- Messages loaded from SQLite in < 10ms
- No API wait time
- No loading spinners

### ✅ Messages NEVER Disappear
- All messages stored in SQLite
- Even if server is down, local data persists
- Sync happens in background

### ✅ No Black/Empty Screens
- Always show cached data
- Graceful degradation
- Friendly error messages

### ✅ No Retry Spam
- Circuit breaker prevents endless retries
- Exponential backoff
- Max retry limits

### ✅ Permission Errors Properly Handled
- Never misclassified as 500/503
- Correct HTTP status code mapping
- User-friendly messages

### ✅ Duplicate Messages Prevented
- Local ID deduplication
- Server ID tracking
- Conflict resolution

---

## 🚀 Usage Example

### Reading Messages
```dart
final result = await repository.getMessages(conversationId, currentUserId);

result.when(
  synced: (messages) => showMessages(messages),
  localOnly: (messages) => showMessages(messages, isOffline: true),
  pendingSync: (messages) => showMessages(messages, isPending: true),
  permissionDenied: (error) => showPermissionError(error),
  serverUnavailable: (error) => showOfflineIndicator(),
);
```

### Sending Message
```dart
final result = await repository.sendMessage(conversationId, content, currentUserId);

// Message is already in SQLite and visible in UI
// Sync happens in background automatically
```

---

## 📝 Final Checklist

- ✅ SQLite is single source of truth
- ✅ UI never waits for API
- ✅ Network errors never break UX
- ✅ Permission errors properly classified
- ✅ Smart retry with circuit breaker
- ✅ Message deduplication
- ✅ Optimistic updates
- ✅ Background sync
- ✅ No black screens
- ✅ No retry spam
- ✅ Graceful degradation

**NO ERROR CAN BREAK THIS APP** ✅

