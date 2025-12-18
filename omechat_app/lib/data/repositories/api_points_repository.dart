import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../repositories/points_repository.dart';
import '../../domain/models/points_models.dart';

class ApiPointsRepository implements PointsRepository {
  final ApiClient _api;

  ApiPointsRepository(this._api);

  @override
  Future<UserPoints> getUserPoints() async {
    final data = await _api.getPointsHistory();
    
    final currentCredits = data['current_credits'] as int;
    final history = (data['history'] as List).map((item) {
      PointsActionType type = PointsActionType.dailyLogin; 
      
      final actionTypeStr = item['action_type'] as String;
      
      if (actionTypeStr == 'daily_login') type = PointsActionType.dailyLogin;
      else if (actionTypeStr == 'purchase') type = PointsActionType.profileCompleted; // using profileCompleted as placeholder for purchase
      else type = PointsActionType.minuteChatted;
      
      return PointsAction(
        id: item['id'],
        type: type,
        points: item['amount'],
        timestamp: DateTime.parse(item['created_at']),
        description: item['description'],
      );
    }).toList();

    return UserPoints(
      totalPoints: currentCredits,
      level: UserPoints.calculateLevel(currentCredits),
      recentActions: history,
    );
  }

  @override
  Future<void> recordAction(PointsActionType type) async {
    if (type == PointsActionType.dailyLogin) {
      await _api.claimDailyPoints();
    }
  }

  @override
  Future<void> buyCredits(int amount) async {
    await _api.buyCredits(amount);
  }

  @override
  Future<List<PointsAction>> getRecentActions({int limit = 10}) async {
    final userPoints = await getUserPoints();
    return userPoints.recentActions.take(limit).toList();
  }

  @override
  List<PointsActionInfo> getAvailableActions() {
    return [
      PointsActionInfo(
        type: PointsActionType.messageSent,
        description: 'Send message',
        points: PointsConfig.messageSent,
        iconName: 'chat_bubble',
      ),
      PointsActionInfo(
        type: PointsActionType.chatStarted,
        description: 'Start chat',
        points: PointsConfig.chatStarted,
        iconName: 'play_arrow',
      ),
      PointsActionInfo(
        type: PointsActionType.chatCompleted,
        description: 'Complete chat (5+ min)',
        points: PointsConfig.chatCompleted,
        iconName: 'check_circle',
      ),
      PointsActionInfo(
        type: PointsActionType.dailyLogin,
        description: 'Daily login',
        points: PointsConfig.dailyLogin,
        iconName: 'today',
      ),
      PointsActionInfo(
        type: PointsActionType.profileCompleted,
        description: 'Complete profile',
        points: PointsConfig.profileCompleted,
        iconName: 'person',
      ),
      PointsActionInfo(
        type: PointsActionType.minuteChatted,
        description: 'Each chat minute',
        points: PointsConfig.minuteChatted,
        iconName: 'timer',
      ),
      PointsActionInfo(
        type: PointsActionType.connectionMade,
        description: 'Connect with someone new',
        points: PointsConfig.connectionMade,
        iconName: 'people',
      ),
    ];
  }
}

final apiPointsRepositoryProvider = Provider<PointsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ApiPointsRepository(api);
});
