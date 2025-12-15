import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../services/friend_service.dart';
import '../domain/models/chat_models.dart';
import '../services/chat_socket_service.dart';
import '../data/repositories/points_repository.dart';
import '../domain/models/points_models.dart';
import '../core/network/network_result.dart';
import '../data/repositories/offline_chat_repository.dart';
import '../data/repositories/chat_stream_repository.dart';
import '../providers/database_providers.dart';
import '../providers/auth_provider.dart';
import 'dart:async';

/// Conversations list provider - OFFLINE-FIRST with SQLite Stream
/// Always returns data from SQLite instantly, updates automatically
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final streamRepository = ref.watch(chatStreamRepositoryProvider);
  return streamRepository.watchConversations();
});

/// Chat controller for sending messages - OFFLINE-FIRST with SQLite Stream
class ChatController extends StateNotifier<AsyncValue<List<Message>>> {
  final OfflineChatRepository _repository;
  final ChatStreamRepository _streamRepository;
  final ChatSocketService _socketService;
  final String conversationId;
  final String currentUserId;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _messageStreamSubscription;

  ChatController(
    this._repository,
    this._streamRepository,
    this._socketService,
    this.conversationId,
    this.currentUserId,
  ) : super(const AsyncValue.loading()) {
    _subscribeToSQLiteStream();
    _subscribeToSocket();
  }

  /// Subscribe to SQLite stream - UI updates automatically
  void _subscribeToSQLiteStream() {
    _messageStreamSubscription = _streamRepository
        .watchMessages(conversationId, currentUserId)
        .listen((messages) {
      // Update state immediately when SQLite changes
      state = AsyncValue.data(messages);
    }, onError: (error) {
      // Even on error, show empty list (never crash)
      state = AsyncValue.data(<Message>[]);
    });
    
    // Initial load
    _loadMessages();
  }

  void _subscribeToSocket() {
    _socketSubscription = _socketService.messages.listen((data) {
      if (data['type'] == 'CHAT_MESSAGE') {
        final msgData = data['message'];
        if (msgData['sender_id'] == conversationId || msgData['receiver_id'] == conversationId) {
          // Message will appear via SQLite stream after being saved
          // Just trigger a refresh
          _streamRepository.refreshMessages(conversationId, currentUserId);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageStreamSubscription?.cancel();
    super.dispose();
  }

  /// Load messages - ALWAYS succeeds (from SQLite)
  Future<void> _loadMessages() async {
    try {
      final result = await _repository.getMessages(conversationId, currentUserId);
      if (result.hasData) {
        state = AsyncValue.data(result.dataOrNull!);
      } else {
        state = AsyncValue.data(<Message>[]);
      }
    } catch (e, st) {
      // Even on error, return empty list (never crash)
      state = AsyncValue.data(<Message>[]);
    }
  }

  /// Send message - ONLY SQLite, NO API, NO NETWORK
  /// Message appears instantly in UI via stream
  /// Send message - ONLY SQLite, NO API, NO NETWORK
  /// Message appears instantly in UI via stream
  Future<void> sendMessage(String text, {String? receiverName}) async {
    if (text.trim().isEmpty) return;
    
    try {
      // Step 1: Write to SQLite (ONLY operation)
      await _repository.sendMessage(
        conversationId, 
        text, 
        currentUserId,
        receiverName: receiverName,
      );
      
      // Step 2: Force immediate stream emit (UI updates instantly)
      await _streamRepository.forceEmitMessages(conversationId, currentUserId);
      
      // Step 3: Update conversation list (shows last message)
      await _streamRepository.refreshConversations();
    } catch (e) {
      // Even on error, try to refresh stream (message might be in SQLite)
      await _streamRepository.forceEmitMessages(conversationId, currentUserId);
    }
  }

  Future<void> refresh() async {
    await _loadMessages();
    await _streamRepository.refreshMessages(conversationId, currentUserId);
  }
}

final chatControllerProvider = StateNotifierProvider.family<
    ChatController,
    AsyncValue<List<Message>>,
    String>(
  (ref, conversationId) {
    final repository = ref.watch(offlineChatRepositoryProvider);
    final streamRepository = ref.watch(chatStreamRepositoryProvider);
    final socketService = ref.watch(chatSocketServiceProvider);
    // Get current user ID from auth
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? 'unknown';
    
    return ChatController(
      repository,
      streamRepository,
      socketService,
      conversationId,
      currentUserId,
    );
  },
);

/// Points repository provider
final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  return MockPointsRepository();
});


// ═══════════════════════════════════════════════════════════════
// POINTS STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Points state notifier
class PointsController extends StateNotifier<AsyncValue<UserPoints>> {
  final PointsRepository _repo;
  final Ref _ref;

  PointsController(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    state = const AsyncValue.loading();
    try {
      final points = await _repo.getUserPoints();
      state = AsyncValue.data(points);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordAction(PointsActionType type) async {
    await _repo.recordAction(type);
    await _loadPoints(); // Refresh after recording
  }

  List<PointsActionInfo> getAvailableActions() {
    return _repo.getAvailableActions();
  }
}

final pointsControllerProvider = StateNotifierProvider<PointsController, AsyncValue<UserPoints>>((ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return PointsController(repo, ref);
});

/// Available actions for display
final availableActionsProvider = Provider<List<PointsActionInfo>>((ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getAvailableActions();
});

// ═══════════════════════════════════════════════════════════════
// GUEST MODE PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Guest usage limits
class GuestLimits {
  static const int maxRandomChats = 3;
  static const int maxMessages = 20;
}

/// Guest usage tracker
class GuestUsageState {
  final int randomChatsUsed;
  final int messagesSent;

  const GuestUsageState({
    this.randomChatsUsed = 0,
    this.messagesSent = 0,
  });

  bool get canStartRandomChat => randomChatsUsed < GuestLimits.maxRandomChats;
  bool get canSendMessage => messagesSent < GuestLimits.maxMessages;
  bool get hasReachedLimit => !canStartRandomChat || !canSendMessage;

  GuestUsageState copyWith({int? randomChatsUsed, int? messagesSent}) {
    return GuestUsageState(
      randomChatsUsed: randomChatsUsed ?? this.randomChatsUsed,
      messagesSent: messagesSent ?? this.messagesSent,
    );
  }
}

class GuestUsageController extends StateNotifier<GuestUsageState> {
  GuestUsageController() : super(const GuestUsageState());

  void recordRandomChat() {
    state = state.copyWith(randomChatsUsed: state.randomChatsUsed + 1);
  }

  void recordMessageSent() {
    state = state.copyWith(messagesSent: state.messagesSent + 1);
  }

  void reset() {
    state = const GuestUsageState();
  }
}

final guestUsageProvider = StateNotifierProvider<GuestUsageController, GuestUsageState>((ref) {
  return GuestUsageController();
});
