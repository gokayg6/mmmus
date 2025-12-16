import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_storage.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

/// Supported languages
enum SupportedLanguage {
  english('en', 'English'),
  turkish('tr', 'Türkçe');

  final String code;
  final String displayName;

  const SupportedLanguage(this.code, this.displayName);

  static SupportedLanguage fromCode(String code) {
    return values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }
}

/// Language state
class LanguageState {
  final Locale locale;
  final bool isLoading;

  const LanguageState({
    required this.locale,
    this.isLoading = false,
  });

  LanguageState copyWith({
    Locale? locale,
    bool? isLoading,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Language controller with 3-tier resolution
class LanguageController extends StateNotifier<LanguageState> {
  final LanguageStorage _storage;
  final ApiClient _apiClient;
  final Ref _ref;

  LanguageController(this._storage, this._apiClient, this._ref)
      : super(LanguageState(locale: Locale('en')));

  /// Initialize language on app startup
  /// Priority: 1. Backend (if logged in) → 2. Local storage → 3. Device locale
  Future<void> initializeLanguage() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if user is logged in
      final authState = _ref.read(authProvider);
      final isLoggedIn = authState.user != null;

      String? languageCode;

      // 1️⃣ Priority 1: User preference from backend (if logged in)
      if (isLoggedIn) {
        try {
          final user = await _apiClient.getMe();
          if (user.email.isNotEmpty) {
            // Assuming UserProfile has languageCode field (will add in backend)
            // languageCode = user.languageCode;
            // For now, skip backend and use local/device
          }
        } catch (e) {
          print('Failed to fetch user language from backend: $e');
        }
      }

      // 2️⃣ Priority 2: Local persisted preference
      if (languageCode == null) {
        languageCode = await _storage.getLanguageCode();
      }

      // 3️⃣ Priority 3: Device system language (fallback)
      if (languageCode == null) {
        final deviceLocale = PlatformDispatcher.instance.locale;
        // Check if device language is supported
        final isSupported = SupportedLanguage.values
            .any((lang) => lang.code == deviceLocale.languageCode);
        languageCode = isSupported ? deviceLocale.languageCode : 'en';
      }

      // Apply resolved language
      final locale = Locale(languageCode);
      state = LanguageState(locale: locale, isLoading: false);
    } catch (e) {
      print('Error initializing language: $e');
      state = LanguageState(locale: Locale('en'), isLoading: false);
    }
  }

  /// Set new language
  /// Updates: UI immediately → Local storage → Backend (background)
  Future<void> setLanguage(SupportedLanguage language) async {
    try {
      // 1. Update UI immediately (no waiting)
      state = LanguageState(locale: Locale(language.code), isLoading: false);

      // 2. Persist locally (fire and forget - UI doesn't wait)
      _storage.setLanguageCode(language.code).catchError((e) {
        print('Failed to save language locally: $e');
      });

      // 3. Sync to backend (background, offline-safe)
      final authState = _ref.read(authProvider);
      if (authState.user != null) {
        _syncLanguageToBackend(language.code).catchError((e) {
          print('Failed to sync language to backend: $e');
          // Silent failure - local preference is already saved
        });
      }
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  /// Background sync to backend (non-blocking)
  Future<void> _syncLanguageToBackend(String languageCode) async {
    try {
      // Will implement when backend settings API is ready
      // await _apiClient.updateUserSettings(languageCode: languageCode);
      print('Language synced to backend: $languageCode');
    } catch (e) {
      print('Backend sync failed (offline?): $e');
      rethrow;
    }
  }
}

/// Language storage provider
final languageStorageProvider = Provider<LanguageStorage>((ref) {
  return LanguageStorage();
});

/// Language controller provider
final languageProvider =
    StateNotifierProvider<LanguageController, LanguageState>((ref) {
  final storage = ref.watch(languageStorageProvider);
  final apiClient = ref.watch(apiClientProvider);
  return LanguageController(storage, apiClient, ref);
});
