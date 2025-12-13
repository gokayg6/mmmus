import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/config/app_config.dart';

/// API client for REST endpoints
class ApiClient {
  late final Dio _dio;
  String? _sessionToken;
  String? _accessToken;
  final String _baseUrl;

  /// Get base URL for WebSocket connection
  String get baseUrl => _baseUrl;
  
  /// Get Dio instance for direct API calls
  Dio get dio => _dio;

  /// === IMPORTANT ===
  /// REAL PHONE → Use your PC's IPv4: 192.168.1.103
  /// ANDROID EMULATOR → 10.0.2.2
  /// iOS SIMULATOR → localhost / 127.0.0.1
  ApiClient({required String baseUrl}) : _baseUrl = baseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    /// Log all requests / responses
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('API Log: $obj'),
      ),
    );
    
    /// Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  void setSessionToken(String token) {
    _sessionToken = token;
  }
  
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
  void clearAccessToken() {
    _accessToken = null;
  }

  // =====================================
  // AUTH ENDPOINTS
  // =====================================
  
  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      _accessToken = data['access_token'];

      return AuthResponse(
        accessToken: data['access_token'],
        user: UserProfile.fromJson(data['user']),
      );
    } on DioException catch (e) {
      String message = 'Kayıt başarısız';
      final data = e.response?.data;
      
      if (data is Map) {
        var detail = data['detail'];
        if (detail is List) {
          message = detail.map((Item) => Item is Map ? (Item['msg'] ?? Item.toString()) : Item.toString()).join(', ');
        } else if (detail != null) {
          message = detail.toString();
        }
      } else if (data != null) {
        message = data.toString();
      }
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    }
  }
  
  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      _accessToken = data['access_token'];

      return AuthResponse(
        accessToken: data['access_token'],
        user: UserProfile.fromJson(data['user']),
      );
    } on DioException catch (e) {
      String message = 'Giriş başarısız';
      final data = e.response?.data;
      
      if (data is Map) {
        var detail = data['detail'];
        if (detail is List) {
          message = detail.map((Item) => Item is Map ? (Item['msg'] ?? Item.toString()) : Item.toString()).join(', ');
        } else if (detail != null) {
          message = detail.toString();
        }
      } else if (data != null) {
        message = data.toString();
      }
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    }
  }
  
  /// Get current user profile
  Future<UserProfile> getMe() async {
    if (_accessToken == null) throw ApiException(message: 'Oturum açılmamış');

    try {
      final response = await _dio.get('/api/v1/auth/me');
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Profil alınamadı';
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    }
  }
  
  /// Update user profile
  Future<UserProfile> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    if (_accessToken == null) throw ApiException(message: 'Oturum açılmamış');

    try {
      final response = await _dio.put(
        '/api/v1/auth/me',
        data: {
          if (username != null) 'username': username,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
        },
      );
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      String message = 'Güncelleme başarısız';
      final data = e.response?.data;
      
      if (data is Map) {
        var detail = data['detail'];
        if (detail is List) {
          message = detail.map((Item) => Item is Map ? (Item['msg'] ?? Item.toString()) : Item.toString()).join(', ');
        } else if (detail != null) {
          message = detail.toString();
        }
      } else if (data != null) {
        message = data.toString();
      }
      throw ApiException(message: message, statusCode: e.response?.statusCode);
    }
  }

  // =====================================
  // SESSION ENDPOINTS
  // =====================================

  /// START SESSION
  Future<SessionResponse> startSession({
    required String deviceType,
    String? gender,
    String? deviceFingerprint,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/public/session/start',
        data: {
          'device_type': deviceType,
          'gender': gender ?? 'UNSPECIFIED',
          'device_fingerprint': deviceFingerprint,
        },
      );

      final data = response.data;
      _sessionToken = data['session_token'];

      return SessionResponse(
        sessionId: data['session_id'],
        sessionToken: data['session_token'],
        iceServers: List<Map<String, dynamic>>.from(data['ice_servers']),
      );
    } catch (e) {
      if (e is DioException) {
        print('Session Start Error: ${e.response?.data}');
      }
      rethrow;
    }
  }

  /// HEARTBEAT
  Future<HeartbeatResponse> heartbeat() async {
    if (_sessionToken == null) throw Exception('No session token');

    final response = await _dio.post(
      '/api/v1/public/session/heartbeat',
      data: {
        'session_token': _sessionToken,
      },
    );

    return HeartbeatResponse(
      success: response.data['success'],
      onlineUsers: response.data['online_users'],
    );
  }

  /// REPORT USER
  Future<ReportResponse> submitReport({
    required String reason,
    String? connectionId,
    String? description,
  }) async {
    if (_sessionToken == null) throw Exception('No session token');

    final response = await _dio.post(
      '/api/v1/public/report',
      data: {
        'session_token': _sessionToken,
        'connection_id': connectionId,
        'reason': reason,
        'description': description,
      },
    );

    return ReportResponse(
      reportId: response.data['report_id'],
      message: response.data['message'],
    );
  }

  /// ONLINE COUNT
  Future<OnlineCountResponse> getOnlineCount() async {
    final response = await _dio.get('/api/v1/public/online-count');

    return OnlineCountResponse(
      onlineUsers: response.data['online_users'],
      inQueue: response.data['in_queue'],
      activeConnections: response.data['active_connections'],
    );
  }

  /// HEALTH CHECK
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/api/v1/public/health');
      return response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}

// =====================================
// RESPONSE MODELS
// =====================================

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class UserProfile {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isActive;
  final int credits;
  final bool isPremium;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    required this.isActive,
    this.credits = 0,
    this.isPremium = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'],
      credits: json['credits'] ?? 0,
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'credits': credits,
      'is_premium': isPremium,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final UserProfile user;

  AuthResponse({
    required this.accessToken,
    required this.user,
  });
}

class SessionResponse {
  final String sessionId;
  final String sessionToken;
  final List<Map<String, dynamic>> iceServers;

  SessionResponse({
    required this.sessionId,
    required this.sessionToken,
    required this.iceServers,
  });
}

class HeartbeatResponse {
  final bool success;
  final int onlineUsers;

  HeartbeatResponse({
    required this.success,
    required this.onlineUsers,
  });
}

class ReportResponse {
  final String reportId;
  final String message;

  ReportResponse({
    required this.reportId,
    required this.message,
  });
}

class OnlineCountResponse {
  final int onlineUsers;
  final int inQueue;
  final int activeConnections;

  OnlineCountResponse({
    required this.onlineUsers,
    required this.inQueue,
    required this.activeConnections,
  });
}

// =====================================
// RIVERPOD PROVIDER
// =====================================

/// Get backend base URL based on platform
String _getBackendBaseUrl() {
  // ═══════════════════════════════════════════════════════════
  // NETWORK CONFIGURATION
  // ═══════════════════════════════════════════════════════════
  
  // Production backend (Railway/Render)
  if (AppConfig.isProduction) {
    return AppConfig.backendUrl;
  }
  
  // Development backend (local)
  // Web platform
  if (kIsWeb) {
    return 'http://localhost:8000';
  }
  
  try {
    if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to reach host machine
      return AppConfig.developmentBackendUrl;
    } else if (Platform.isIOS) {
      // iOS Simulator uses localhost
      return 'http://localhost:8000';
    }
  } catch (e) {
    // Fallback
  }
  
  // Default fallback
  return AppConfig.developmentBackendUrl;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  /// Backend URL Configuration
  /// 
  /// REAL PHONE/DEVICE → Use your PC's local IPv4 address
  /// Find it with: ipconfig (Windows) or ifconfig (Linux/Mac)
  /// Common IPs: 192.168.1.x, 192.168.0.x, 10.0.0.x
  /// 
  /// ANDROID EMULATOR → Uses: http://10.0.2.2:8000
  /// iOS SIMULATOR → Uses: http://localhost:8000
  /// 
  /// IMPORTANT: For real Android devices, edit _getBackendBaseUrl() 
  /// and change the IP to match your PC's IP address!
  
  final baseUrl = _getBackendBaseUrl();
  print('API Base URL: $baseUrl');
  return ApiClient(baseUrl: baseUrl);
});
