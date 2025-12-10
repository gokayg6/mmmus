import 'user.dart';

/// OmeChat Call Model
class Call {
  final String id;
  final User user;
  final CallType type;
  final CallDirection direction;
  final CallStatus status;
  final DateTime timestamp;
  final Duration? duration;
  
  const Call({
    required this.id,
    required this.user,
    required this.type,
    required this.direction,
    required this.status,
    required this.timestamp,
    this.duration,
  });
  
  /// Check if call was missed
  bool get isMissed => status == CallStatus.missed;
  
  /// Get formatted duration
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  Call copyWith({
    String? id,
    User? user,
    CallType? type,
    CallDirection? direction,
    CallStatus? status,
    DateTime? timestamp,
    Duration? duration,
  }) {
    return Call(
      id: id ?? this.id,
      user: user ?? this.user,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
    );
  }
}

enum CallType {
  voice,
  video,
}

enum CallDirection {
  incoming,
  outgoing,
}

enum CallStatus {
  missed,
  answered,
  declined,
}
