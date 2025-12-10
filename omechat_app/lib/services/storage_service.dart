import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage Service - Persistent local storage for app settings and auth tokens
class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserUsername = 'user_username';
  static const String _keyUserAvatarUrl = 'user_avatar_url';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyLanguage = 'language';
  static const String _keyPoints = 'user_points';
  
  final SharedPreferences _prefs;
  
  StorageService(this._prefs);
  
  // =====================================
  // AUTH TOKEN
  // =====================================
  
  String? getAccessToken() => _prefs.getString(_keyAccessToken);
  
  Future<void> setAccessToken(String token) async {
    await _prefs.setString(_keyAccessToken, token);
  }
  
  Future<void> clearAccessToken() async {
    await _prefs.remove(_keyAccessToken);
  }
  
  // =====================================
  // USER INFO
  // =====================================
  
  String? getUserId() => _prefs.getString(_keyUserId);
  String? getUserEmail() => _prefs.getString(_keyUserEmail);
  String? getUserUsername() => _prefs.getString(_keyUserUsername);
  String? getUserAvatarUrl() => _prefs.getString(_keyUserAvatarUrl);
  
  Future<void> saveUserInfo({
    required String id,
    required String email,
    required String username,
    String? avatarUrl,
  }) async {
    await _prefs.setString(_keyUserId, id);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserUsername, username);
    if (avatarUrl != null) {
      await _prefs.setString(_keyUserAvatarUrl, avatarUrl);
    }
  }
  
  Future<void> clearUserInfo() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserUsername);
    await _prefs.remove(_keyUserAvatarUrl);
  }
  
  bool isLoggedIn() => getAccessToken() != null;
  
  // =====================================
  // THEME
  // =====================================
  
  /// Returns 'dark', 'light', or 'system'
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'dark';
  
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }
  
  // =====================================
  // ONBOARDING
  // =====================================
  
  bool isOnboardingComplete() => _prefs.getBool(_keyOnboardingComplete) ?? false;
  
  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_keyOnboardingComplete, value);
  }
  
  // =====================================
  // LANGUAGE
  // =====================================
  
  String getLanguage() => _prefs.getString(_keyLanguage) ?? 'tr';
  
  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_keyLanguage, lang);
  }
  
  // =====================================
  // POINTS
  // =====================================
  
  int getPoints() => _prefs.getInt(_keyPoints) ?? 0;
  
  Future<void> setPoints(int points) async {
    await _prefs.setInt(_keyPoints, points);
  }
  
  Future<void> addPoints(int amount) async {
    final current = getPoints();
    await setPoints(current + amount);
  }
  
  // =====================================
  // CLEAR ALL
  // =====================================
  
  Future<void> clearAll() async {
    await _prefs.clear();
  }
  
  Future<void> logout() async {
    await clearAccessToken();
    await clearUserInfo();
  }
}

/// Provider for StorageService - must be initialized in main.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main.dart');
});
