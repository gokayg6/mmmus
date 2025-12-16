import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting language preferences locally
class LanguageStorage {
  static const String _languageKey = 'selected_language_code';
  
  /// Get stored language code
  Future<String?> getLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      print('Error reading language preference: $e');
      return null;
    }
  }
  
  /// Save language code to local storage
  Future<bool> setLanguageCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, code);
    } catch (e) {
      print('Error saving language preference: $e');
      return false;
    }
  }
  
  /// Clear stored language preference
  Future<bool> clearLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_languageKey);
    } catch (e) {
      print('Error clearing language preference: $e');
      return false;
    }
  }
}
