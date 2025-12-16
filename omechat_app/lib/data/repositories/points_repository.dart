import '../../domain/models/points_models.dart';

/// Repository interface for points/score operations
abstract class PointsRepository {
  /// Get current user points
  Future<UserPoints> getUserPoints();
  
  /// Record a points-earning action
  Future<void> recordAction(PointsActionType type);
  
  /// Get recent actions
  Future<List<PointsAction>> getRecentActions({int limit = 10});
  
  /// Get all available action types with their point values
  List<PointsActionInfo> getAvailableActions();
}

/// Info about a points action for display
class PointsActionInfo {
  final PointsActionType type;
  final String description;
  final int points;
  final String iconName;

  const PointsActionInfo({
    required this.type,
    required this.description,
    required this.points,
    required this.iconName,
  });
}

/// Mock implementation of PointsRepository
class MockPointsRepository implements PointsRepository {
  int _totalPoints = 150;
  final List<PointsAction> _actions = [];

  @override
  Future<UserPoints> getUserPoints() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final level = UserPoints.calculateLevel(_totalPoints);
    return UserPoints(
      totalPoints: _totalPoints,
      level: level,
      pointsToNextLevel: _pointsForLevel(level + 1) - _totalPoints,
      recentActions: _actions.take(5).toList(),
    );
  }

  int _pointsForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level) * 25).toInt();
  }

  @override
  Future<void> recordAction(PointsActionType type) async {
    final points = PointsConfig.getPointsForAction(type);
    _totalPoints += points;
    
    _actions.insert(0, PointsAction(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      points: points,
      timestamp: DateTime.now(),
      description: PointsConfig.getActionDescription(type),
    ));
  }

  @override
  Future<List<PointsAction>> getRecentActions({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _actions.take(limit).toList();
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
