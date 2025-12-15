import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../domain/models/user_models.dart'; // We'll need to create or update this for FriendResponse

// Temporary model definitions if not exists, or update existing files later
class FriendRequest {
  final String id;
  final Friend friend;
  final String status;

  FriendRequest({required this.id, required this.friend, required this.status});
  
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      friend: Friend.fromJson(json['friend']),
      status: json['status'],
    );
  }
}

class Friend {
  final String id;
  final String username;
  final String? avatarUrl;

  Friend({required this.id, required this.username, this.avatarUrl});

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }
}

class FriendService {
  final ApiClient _apiClient;

  FriendService(this._apiClient);

  /// Send friend request
  Future<FriendRequest> sendRequest(String username) async {
    final response = await _apiClient.dio.post(
      '/api/v1/friends/request',
      data: {'username': username},
    );
    return FriendRequest.fromJson(response.data);
  }

  /// Accept friend request
  Future<void> acceptRequest(String friendshipId) async {
    await _apiClient.dio.post('/api/v1/friends/$friendshipId/accept');
  }

  /// Get friends list
  Future<List<FriendRequest>> getFriends() async {
    final response = await _apiClient.dio.get('/api/v1/friends/');
    return (response.data as List).map((e) => FriendRequest.fromJson(e)).toList();
  }

  /// Get incoming requests
  Future<List<FriendRequest>> getIncomingRequests() async {
    final response = await _apiClient.dio.get('/api/v1/friends/requests/incoming');
    return (response.data as List).map((e) => FriendRequest.fromJson(e)).toList();
  }
}

final friendServiceProvider = Provider<FriendService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FriendService(apiClient);
});
