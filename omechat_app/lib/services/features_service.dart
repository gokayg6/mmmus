import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import 'storage_service.dart';

/// Feature costs (must match backend)
class FeatureCosts {
  static const int genderFilter = 30;
  static const int countryFilter = 20;
  static const int reconnect = 40;
  static const int hdQuality = 15;
  static const int faceFilters = 10;
  static const int vipBadge = 50;
}

/// User features status model
class UserFeatures {
  final int credits;
  final bool isPremium;
  final String? premiumUntil;
  final bool genderFilterUnlocked;
  final bool countryFilterUnlocked;
  final bool reconnectUnlocked;
  final bool hdQualityUnlocked;
  final bool faceFiltersUnlocked;
  final bool vipBadgeUnlocked;
  // Computed
  final bool canUseGenderFilter;
  final bool canUseCountryFilter;
  final bool canUseReconnect;
  final bool canUseHdQuality;
  final bool canUseFaceFilters;
  final bool canUseVipBadge;

  UserFeatures({
    required this.credits,
    required this.isPremium,
    this.premiumUntil,
    required this.genderFilterUnlocked,
    required this.countryFilterUnlocked,
    required this.reconnectUnlocked,
    required this.hdQualityUnlocked,
    required this.faceFiltersUnlocked,
    required this.vipBadgeUnlocked,
    required this.canUseGenderFilter,
    required this.canUseCountryFilter,
    required this.canUseReconnect,
    required this.canUseHdQuality,
    required this.canUseFaceFilters,
    required this.canUseVipBadge,
  });

  factory UserFeatures.empty() => UserFeatures(
    credits: 0,
    isPremium: false,
    genderFilterUnlocked: false,
    countryFilterUnlocked: false,
    reconnectUnlocked: false,
    hdQualityUnlocked: false,
    faceFiltersUnlocked: false,
    vipBadgeUnlocked: false,
    canUseGenderFilter: false,
    canUseCountryFilter: false,
    canUseReconnect: false,
    canUseHdQuality: false,
    canUseFaceFilters: false,
    canUseVipBadge: false,
  );

  factory UserFeatures.fromJson(Map<String, dynamic> json) => UserFeatures(
    credits: json['credits'] ?? 0,
    isPremium: json['is_premium'] == true,
    premiumUntil: json['premium_until']?.toString(),
    genderFilterUnlocked: json['gender_filter_unlocked'] == true,
    countryFilterUnlocked: json['country_filter_unlocked'] == true,
    reconnectUnlocked: json['reconnect_unlocked'] == true,
    hdQualityUnlocked: json['hd_quality_unlocked'] == true,
    faceFiltersUnlocked: json['face_filters_unlocked'] == true,
    vipBadgeUnlocked: json['vip_badge_unlocked'] == true,
    canUseGenderFilter: json['can_use_gender_filter'] == true,
    canUseCountryFilter: json['can_use_country_filter'] == true,
    canUseReconnect: json['can_use_reconnect'] == true,
    canUseHdQuality: json['can_use_hd_quality'] == true,
    canUseFaceFilters: json['can_use_face_filters'] == true,
    canUseVipBadge: json['can_use_vip_badge'] == true,
  );

  bool canAfford(int cost) => credits >= cost;
}

/// Unlock result model
class UnlockResult {
  final bool success;
  final String message;
  final String feature;
  final int creditsSpent;
  final int remainingCredits;

  UnlockResult({
    required this.success,
    required this.message,
    required this.feature,
    required this.creditsSpent,
    required this.remainingCredits,
  });

  factory UnlockResult.fromJson(Map<String, dynamic> json) => UnlockResult(
    success: json['success'] == true,
    message: json['message']?.toString() ?? '',
    feature: json['feature']?.toString() ?? '',
    creditsSpent: json['credits_spent'] ?? 0,
    remainingCredits: json['remaining_credits'] ?? 0,
  );
}

/// Features Service - Handles feature unlocking with credits
class FeaturesService {
  final Dio _dio;
  final StorageService _storage;

  FeaturesService({required String baseUrl, required StorageService storage})
      : _storage = storage,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// Get current user's feature status
  Future<UserFeatures> getFeatureStatus() async {
    try {
      final response = await _dio.get('/api/v1/features/status');
      return UserFeatures.fromJson(response.data);
    } on DioException catch (e) {
      throw FeaturesException(
        message: e.response?.data?['detail']?.toString() ?? 'Özellik durumu alınamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Unlock a feature by spending credits
  Future<UnlockResult> unlockFeature(String featureName) async {
    try {
      final response = await _dio.post('/api/v1/features/unlock/$featureName');
      return UnlockResult.fromJson(response.data);
    } on DioException catch (e) {
      throw FeaturesException(
        message: e.response?.data?['detail']?.toString() ?? 'Özellik açılamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Check if a specific feature is available
  Future<bool> canUseFeature(String featureName) async {
    try {
      final response = await _dio.get('/api/v1/features/check/$featureName');
      return response.data['is_unlocked'] == true;
    } catch (e) {
      return false;
    }
  }
}

class FeaturesException implements Exception {
  final String message;
  final int? statusCode;

  FeaturesException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

// =====================================
// PROVIDERS
// =====================================

String _getBaseUrl() {
  return AppConfig.backendUrl;
}

final featuresServiceProvider = Provider<FeaturesService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FeaturesService(baseUrl: _getBaseUrl(), storage: storage);
});

/// Provider for user features - auto-refreshes
final userFeaturesProvider = FutureProvider<UserFeatures>((ref) async {
  final service = ref.watch(featuresServiceProvider);
  try {
    return await service.getFeatureStatus();
  } catch (e) {
    return UserFeatures.empty();
  }
});

/// State notifier for features with refresh capability
class FeaturesNotifier extends StateNotifier<AsyncValue<UserFeatures>> {
  final FeaturesService _service;

  FeaturesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadFeatures();
  }

  Future<void> loadFeatures() async {
    state = const AsyncValue.loading();
    try {
      final features = await _service.getFeatureStatus();
      state = AsyncValue.data(features);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UnlockResult?> unlockFeature(String featureName) async {
    try {
      final result = await _service.unlockFeature(featureName);
      // Reload features after unlock
      await loadFeatures();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

final featuresNotifierProvider = StateNotifierProvider<FeaturesNotifier, AsyncValue<UserFeatures>>((ref) {
  final service = ref.watch(featuresServiceProvider);
  return FeaturesNotifier(service);
});

