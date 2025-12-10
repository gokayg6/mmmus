import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';

/// Authentication State
enum AuthStatus {
  unknown,    // Initial state
  checking,   // Checking saved token
  authenticated,
  unauthenticated,
}

/// Auth State Model
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;
  
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });
  
  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
  
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.checking || status == AuthStatus.unknown;
}

/// Auth Provider - Manages authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storage;
  final ApiClient _api;
  
  AuthNotifier(this._storage, this._api) : super(const AuthState()) {
    _checkSavedAuth();
  }
  
  /// Check for saved authentication on startup
  Future<void> _checkSavedAuth() async {
    state = state.copyWith(status: AuthStatus.checking);
    
    final token = _storage.getAccessToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    
    // Token exists, set it and try to get user profile
    _api.setAccessToken(token);
    
    try {
      final user = await _api.getMe();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      // Token invalid or expired
      await _storage.logout();
      _api.clearAccessToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }
  
  /// Register new user
  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _api.register(
        email: email,
        username: username,
        password: password,
      );
      
      // Save to storage
      await _storage.setAccessToken(response.accessToken);
      await _storage.saveUserInfo(
        id: response.user.id,
        email: response.user.email,
        username: response.user.username,
        avatarUrl: response.user.avatarUrl,
      );
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
      
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Bağlantı hatası: $e');
      return false;
    }
  }
  
  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.login(
        email: email,
        password: password,
      );
      
      // Save to storage
      await _storage.setAccessToken(response.accessToken);
      await _storage.saveUserInfo(
        id: response.user.id,
        email: response.user.email,
        username: response.user.username,
        avatarUrl: response.user.avatarUrl,
      );
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: response.user,
      );
      
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Bağlantı hatası: $e');
      return false;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await _storage.logout();
    _api.clearAccessToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
  
  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  /// Refresh user profile
  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    
    try {
      final user = await _api.getMe();
      state = state.copyWith(user: user);
    } catch (e) {
      // Silent fail
    }
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(storage, api);
});
