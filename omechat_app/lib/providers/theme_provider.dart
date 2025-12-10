import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Theme Mode Provider - Manages app theme (dark/light)
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;
  
  ThemeNotifier(this._storage) : super(_loadInitialTheme(_storage));
  
  static ThemeMode _loadInitialTheme(StorageService storage) {
    final saved = storage.getThemeMode();
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }
  
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
      default:
        modeStr = 'dark';
    }
    
    await _storage.setThemeMode(modeStr);
  }
  
  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }
  
  bool get isDarkMode => state == ThemeMode.dark;
  bool get isLightMode => state == ThemeMode.light;
}

/// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeNotifier(storage);
});

/// Onboarding Complete Provider
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.isOnboardingComplete();
});

/// Points Provider
class PointsNotifier extends StateNotifier<int> {
  final StorageService _storage;
  
  PointsNotifier(this._storage) : super(_storage.getPoints());
  
  Future<void> addPoints(int amount) async {
    state = state + amount;
    await _storage.setPoints(state);
  }
  
  Future<void> setPoints(int points) async {
    state = points;
    await _storage.setPoints(state);
  }
}

final pointsProvider = StateNotifierProvider<PointsNotifier, int>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PointsNotifier(storage);
});
