/// User model for friend responses
class FriendUser {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isOnline;

  const FriendUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    return FriendUser(
      id: json['id'] ?? json['friend_id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
    );
  }
}

/// Friend response from API
class FriendResponse {
  final String id;
  final FriendUser friend;
  final String status;
  final DateTime createdAt;

  const FriendResponse({
    required this.id,
    required this.friend,
    required this.status,
    required this.createdAt,
  });

  factory FriendResponse.fromJson(Map<String, dynamic> json) {
    return FriendResponse(
      id: json['id'] ?? '',
      friend: FriendUser.fromJson(json['friend'] ?? {}),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
