import 'package:flutter/foundation.dart';

/// User model for the app
class UserModel {
  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final bool isGuest;
  final bool isPremium;
  final DateTime createdAt;
  final UserStats stats;

  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.isGuest = false,
    this.isPremium = false,
    required this.createdAt,
    this.stats = const UserStats(),
  });

  String get initials {
    if (username.isEmpty) return '?';
    final parts = username.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    bool? isGuest,
    bool? isPremium,
    DateTime? createdAt,
    UserStats? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
    );
  }

  factory UserModel.guest() {
    return UserModel(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      username: 'Misafir',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }
}

/// User statistics
@immutable
class UserStats {
  final int totalChats;
  final int totalMinutes;
  final int totalConnections;
  final int messagesSent;

  const UserStats({
    this.totalChats = 0,
    this.totalMinutes = 0,
    this.totalConnections = 0,
    this.messagesSent = 0,
  });

  UserStats copyWith({
    int? totalChats,
    int? totalMinutes,
    int? totalConnections,
    int? messagesSent,
  }) {
    return UserStats(
      totalChats: totalChats ?? this.totalChats,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      totalConnections: totalConnections ?? this.totalConnections,
      messagesSent: messagesSent ?? this.messagesSent,
    );
  }
}
