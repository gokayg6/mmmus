/// Points action model - records user actions that earn points
class PointsAction {
  final String id;
  final PointsActionType type;
  final int points;
  final DateTime timestamp;
  final String? description;

  const PointsAction({
    required this.id,
    required this.type,
    required this.points,
    required this.timestamp,
    this.description,
  });
}

enum PointsActionType {
  messageSent,
  chatStarted,
  chatCompleted,
  dailyLogin,
  profileCompleted,
  minuteChatted,
  connectionMade,
}

/// Points configuration - defines how many points each action is worth
class PointsConfig {
  static const int messageSent = 1;
  static const int chatStarted = 5;
  static const int chatCompleted = 10;
  static const int dailyLogin = 25;
  static const int profileCompleted = 50;
  static const int minuteChatted = 2;
  static const int connectionMade = 5;

  static int getPointsForAction(PointsActionType type) {
    switch (type) {
      case PointsActionType.messageSent:
        return messageSent;
      case PointsActionType.chatStarted:
        return chatStarted;
      case PointsActionType.chatCompleted:
        return chatCompleted;
      case PointsActionType.dailyLogin:
        return dailyLogin;
      case PointsActionType.profileCompleted:
        return profileCompleted;
      case PointsActionType.minuteChatted:
        return minuteChatted;
      case PointsActionType.connectionMade:
        return connectionMade;
    }
  }

  static String getActionDescription(PointsActionType type) {
    switch (type) {
      case PointsActionType.messageSent:
        return 'Send message';
      case PointsActionType.chatStarted:
        return 'Start chat';
      case PointsActionType.chatCompleted:
        return 'Complete chat';
      case PointsActionType.dailyLogin:
        return 'Daily login';
      case PointsActionType.profileCompleted:
        return 'Complete profile';
      case PointsActionType.minuteChatted:
        return '1 minute chatted';
      case PointsActionType.connectionMade:
        return 'New connection';
    }
  }
}

/// User points summary
class UserPoints {
  final int totalPoints;
  final int level;
  final int pointsToNextLevel;
  final List<PointsAction> recentActions;

  const UserPoints({
    this.totalPoints = 0,
    this.level = 1,
    this.pointsToNextLevel = 100,
    this.recentActions = const [],
  });

  double get progressToNextLevel {
    final currentLevelBase = _pointsForLevel(level);
    final nextLevelPoints = _pointsForLevel(level + 1);
    final pointsInCurrentLevel = totalPoints - currentLevelBase;
    final pointsNeeded = nextLevelPoints - currentLevelBase;
    return pointsInCurrentLevel / pointsNeeded;
  }

  static int _pointsForLevel(int level) {
    // Level 1: 0, Level 2: 100, Level 3: 250, Level 4: 500, etc.
    if (level <= 1) return 0;
    return ((level - 1) * (level) * 25).toInt();
  }

  static int calculateLevel(int points) {
    int level = 1;
    while (_pointsForLevel(level + 1) <= points) {
      level++;
    }
    return level;
  }
}
