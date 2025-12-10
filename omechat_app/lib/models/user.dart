/// OmeChat User Model
class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  
  const User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });
  
  /// Get initials for avatar placeholder
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
  
  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
