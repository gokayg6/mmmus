import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import 'api_client.dart';
import 'storage_service.dart';

/// Admin API Service
class AdminService {
  final Dio _dio;
  String? _adminToken;

  AdminService({required String baseUrl}) : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_adminToken != null) {
          options.headers['Authorization'] = 'Bearer $_adminToken';
        }
        handler.next(options);
      },
    ));
  }

  void setToken(String token) {
    _adminToken = token;
  }

  void clearToken() {
    _adminToken = null;
  }

  bool get isAuthenticated => _adminToken != null;

  // =====================================
  // AUTH
  // =====================================

  Future<AdminLoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/admin/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data;
      _adminToken = data['access_token'];
      return AdminLoginResponse(
        accessToken: data['access_token'],
        adminId: data['admin_id'],
        role: data['role'],
        expiresIn: data['expires_in'],
      );
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Giriş başarısız',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AdminProfile> getMe() async {
    try {
      final response = await _dio.get('/api/v1/admin/me');
      return AdminProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Profil alınamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // =====================================
  // STATS
  // =====================================

  Future<DashboardStats> getStats() async {
    try {
      final response = await _dio.get('/api/v1/admin/stats/overview');
      return DashboardStats.fromJson(response.data);
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'İstatistikler alınamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // =====================================
  // USERS
  // =====================================

  Future<UsersResponse> getUsers({
    String? search,
    bool? isPremium,
    bool? isBanned,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (search != null) params['search'] = search;
      if (isPremium != null) params['is_premium'] = isPremium;
      if (isBanned != null) params['is_banned'] = isBanned;

      final response = await _dio.get('/api/v1/admin/users', queryParameters: params);
      return UsersResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Kullanıcılar alınamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> giveCredits(String userId, int amount) async {
    try {
      await _dio.post(
        '/api/v1/admin/users/$userId/credits',
        queryParameters: {'amount': amount},
      );
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Kredi verilemedi',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> givePremium(String userId, int days) async {
    try {
      await _dio.post(
        '/api/v1/admin/users/$userId/premium',
        queryParameters: {'days': days},
      );
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Premium verilemedi',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> banUser(String userId, String reason) async {
    try {
      await _dio.post(
        '/api/v1/admin/users/$userId/ban',
        queryParameters: {'reason': reason},
      );
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Kullanıcı banlanamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _dio.post('/api/v1/admin/users/$userId/unban');
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Ban kaldırılamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // =====================================
  // REPORTS
  // =====================================

  Future<List<ReportItem>> getReports({String? status, int skip = 0, int limit = 50}) async {
    try {
      final params = <String, dynamic>{'skip': skip, 'limit': limit};
      if (status != null) params['status'] = status;

      final response = await _dio.get('/api/v1/admin/reports', queryParameters: params);
      return (response.data as List).map((e) => ReportItem.fromJson(e)).toList();
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Raporlar alınamadı',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> resolveReport(String reportId, String action) async {
    try {
      await _dio.post(
        '/api/v1/admin/reports/$reportId/resolve',
        queryParameters: {'action': action},
      );
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Rapor çözümlenemedi',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // =====================================
  // BROADCAST
  // =====================================

  Future<void> sendBroadcast(String message) async {
    try {
      await _dio.post(
        '/api/v1/admin/broadcast',
        queryParameters: {'message': message},
      );
    } on DioException catch (e) {
      throw AdminException(
        message: e.response?.data?['detail'] ?? 'Duyuru gönderilemedi',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

// =====================================
// MODELS
// =====================================

class AdminException implements Exception {
  final String message;
  final int? statusCode;
  AdminException({required this.message, this.statusCode});
  @override
  String toString() => message;
}

class AdminLoginResponse {
  final String accessToken;
  final String adminId;
  final String role;
  final int expiresIn;

  AdminLoginResponse({
    required this.accessToken,
    required this.adminId,
    required this.role,
    required this.expiresIn,
  });
}

class AdminProfile {
  final String id;
  final String email;
  final String? name;
  final String role;

  AdminProfile({required this.id, required this.email, this.name, required this.role});

  factory AdminProfile.fromJson(Map<String, dynamic> json) => AdminProfile(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    name: json['name']?.toString(),
    role: json['role']?.toString() ?? 'ADMIN',
  );
}

class DashboardStats {
  final int totalUsers;
  final int onlineUsers;
  final int premiumUsers;
  final int bannedUsers;
  final int activeConnections;
  final int usersToday;
  final int pendingReports;
  final int totalReports;
  final double todayRevenue;
  final double monthlyRevenue;
  final double premiumRevenue;
  final double creditsRevenue;
  final double adsRevenue;

  DashboardStats({
    required this.totalUsers,
    required this.onlineUsers,
    required this.premiumUsers,
    required this.bannedUsers,
    required this.activeConnections,
    required this.usersToday,
    required this.pendingReports,
    required this.totalReports,
    required this.todayRevenue,
    required this.monthlyRevenue,
    required this.premiumRevenue,
    required this.creditsRevenue,
    required this.adsRevenue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalUsers: json['total_users'] ?? 0,
    onlineUsers: json['online_users'] ?? 0,
    premiumUsers: json['premium_users'] ?? 0,
    bannedUsers: json['banned_users'] ?? 0,
    activeConnections: json['active_connections'] ?? 0,
    usersToday: json['users_today'] ?? 0,
    pendingReports: json['pending_reports'] ?? 0,
    totalReports: json['total_reports'] ?? 0,
    todayRevenue: (json['today_revenue'] ?? 0).toDouble(),
    monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
    premiumRevenue: (json['premium_revenue'] ?? 0).toDouble(),
    creditsRevenue: (json['credits_revenue'] ?? 0).toDouble(),
    adsRevenue: (json['ads_revenue'] ?? 0).toDouble(),
  );
}

class UsersResponse {
  final int total;
  final List<UserItem> users;

  UsersResponse({required this.total, required this.users});

  factory UsersResponse.fromJson(Map<String, dynamic> json) => UsersResponse(
    total: json['total'] ?? 0,
    users: (json['users'] as List?)?.map((e) => UserItem.fromJson(e)).toList() ?? [],
  );
}

class UserItem {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final bool isPremium;
  final String? premiumUntil;
  final int credits;
  final bool isBanned;
  final bool isActive;
  final String createdAt;
  final String? lastLoginAt;

  UserItem({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.isPremium,
    this.premiumUntil,
    required this.credits,
    required this.isBanned,
    required this.isActive,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) => UserItem(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    username: json['username']?.toString() ?? 'Kullanıcı',
    avatarUrl: json['avatar_url']?.toString(),
    isPremium: json['is_premium'] == true,
    premiumUntil: json['premium_until']?.toString(),
    credits: (json['credits'] is int) ? json['credits'] : int.tryParse(json['credits']?.toString() ?? '0') ?? 0,
    isBanned: json['is_banned'] == true,
    isActive: json['is_active'] != false,
    createdAt: json['created_at']?.toString() ?? '',
    lastLoginAt: json['last_login_at']?.toString(),
  );
}

class ReportItem {
  final String id;
  final String? reporterSessionId;
  final String? reportedSessionId;
  final String reason;
  final String? description;
  final String status;
  final String createdAt;
  final String? resolvedAt;

  ReportItem({
    required this.id,
    this.reporterSessionId,
    this.reportedSessionId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) => ReportItem(
    id: json['id']?.toString() ?? '',
    reporterSessionId: json['reporter_session_id']?.toString(),
    reportedSessionId: json['reported_session_id']?.toString(),
    reason: json['reason']?.toString() ?? 'OTHER',
    description: json['description']?.toString(),
    status: json['status']?.toString() ?? 'PENDING',
    createdAt: json['created_at']?.toString() ?? '',
    resolvedAt: json['resolved_at']?.toString(),
  );

  bool get isPending => status == 'PENDING' || status == 'NEW' || status == 'UNDER_REVIEW';
}

// =====================================
// PROVIDER
// =====================================

String _getAdminBaseUrl() {
  return AppConfig.backendUrl;
}

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(baseUrl: _getAdminBaseUrl());
});

