import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/points_repository.dart';
import '../domain/models/chat_models.dart';
import '../domain/models/points_models.dart';

// ═══════════════════════════════════════════════════════════════
// REPOSITORY PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});

/// Points repository provider
final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  return MockPointsRepository();
});

// ═══════════════════════════════════════════════════════════════
// CHAT STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Conversations list provider
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversations();
});

/// Messages for a specific conversation
final messagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(conversationId);
});

/// Chat controller for sending messages
class ChatController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repo;
  final String conversationId;

  ChatController(this._repo, this.conversationId) : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repo.getMessages(conversationId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      final message = await _repo.sendMessage(conversationId, text);
      state.whenData((messages) {
        state = AsyncValue.data([...messages, message]);
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> refresh() async {
    await _loadMessages();
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, AsyncValue<List<ChatMessage>>, String>(
  (ref, conversationId) {
    final repo = ref.watch(chatRepositoryProvider);
    return ChatController(repo, conversationId);
  },
);

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
