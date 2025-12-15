/// Production-Grade Dio Interceptor
/// 
/// Features:
/// - Request fingerprinting for deduplication
/// - Smart retry with exponential backoff
/// - Circuit breaker pattern
/// - Permission error classification
/// - Never throws raw exceptions to UI
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:collection';
import 'network_result.dart';

class ProductionDioInterceptor extends Interceptor {
  // Retry configuration
  static const int MAX_RETRIES = 3;
  static const Duration INITIAL_BACKOFF = Duration(seconds: 1);
  static const Duration MAX_BACKOFF = Duration(seconds: 30);
  
  // Circuit breaker configuration
  static const int CIRCUIT_BREAKER_FAILURE_THRESHOLD = 5;
  static const Duration CIRCUIT_BREAKER_TIMEOUT = Duration(seconds: 60);
  
  // Request fingerprinting (prevent duplicate requests)
  final Map<String, DateTime> _requestFingerprints = {};
  static const Duration FINGERPRINT_TTL = Duration(seconds: 5);
  
  // Circuit breaker state
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerOpenUntil;
  bool get _isCircuitBreakerOpen {
    if (_circuitBreakerOpenUntil == null) return false;
    if (DateTime.now().isAfter(_circuitBreakerOpenUntil!)) {
      _circuitBreakerOpenUntil = null;
      _consecutiveFailures = 0;
      return false;
    }
    return true;
  }
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate request fingerprint
    final fingerprint = _generateFingerprint(options);
    
    // Check for duplicate requests
    if (_requestFingerprints.containsKey(fingerprint)) {
      final lastRequest = _requestFingerprints[fingerprint]!;
      if (DateTime.now().difference(lastRequest) < FINGERPRINT_TTL) {
        developer.log(
          'Duplicate request detected: ${options.uri}',
          name: 'DioInterceptor',
        );
        // Allow the request but mark it
        options.extra['is_duplicate'] = true;
      }
    }
    
    _requestFingerprints[fingerprint] = DateTime.now();
    
    // Clean old fingerprints
    _cleanOldFingerprints();
    
    // Check circuit breaker
    if (_isCircuitBreakerOpen) {
      developer.log(
        'Circuit breaker is OPEN - rejecting request',
        name: 'DioInterceptor',
      );
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: ServerUnavailable(
            message: 'Service temporarily unavailable. Please try again later.',
            retryable: true,
            retryAfter: _circuitBreakerOpenUntil,
          ),
        ),
      );
      return;
    }
    
    // Initialize retry count
    options.extra['retryCount'] ??= 0;
    
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Reset circuit breaker on success
    _consecutiveFailures = 0;
    _circuitBreakerOpenUntil = null;
    
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    developer.log(
      'API Error: ${err.requestOptions.uri} [${err.response?.statusCode}]',
      error: err,
      name: 'DioInterceptor',
      level: 900,
    );
    
    // Classify error
    final errorType = _classifyError(err);
    
    // Update circuit breaker
    if (errorType is ServerUnavailable) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= CIRCUIT_BREAKER_FAILURE_THRESHOLD) {
        _circuitBreakerOpenUntil = DateTime.now().add(CIRCUIT_BREAKER_TIMEOUT);
        developer.log(
          'Circuit breaker OPENED after $_consecutiveFailures failures',
          name: 'DioInterceptor',
        );
      }
    } else {
      // Reset on non-server errors
      _consecutiveFailures = 0;
    }
    
    // Handle retry logic
    final shouldRetry = _shouldRetry(err, errorType);
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    if (shouldRetry && retryCount < MAX_RETRIES) {
      final newRetryCount = retryCount + 1;
      err.requestOptions.extra['retryCount'] = newRetryCount;
      
      // Exponential backoff with jitter
      final baseDelay = INITIAL_BACKOFF * (1 << (newRetryCount - 1));
      final jitter = Duration(milliseconds: (baseDelay.inMilliseconds * 0.1).round());
      final delay = baseDelay + jitter;
      final finalDelay = delay > MAX_BACKOFF ? MAX_BACKOFF : delay;
      
      developer.log(
        'Retrying request ($newRetryCount/$MAX_RETRIES) after ${finalDelay.inSeconds}s',
        name: 'DioInterceptor',
      );
      
      await Future.delayed(finalDelay);
      
      try {
        // Retry the request
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        _consecutiveFailures = 0; // Reset on successful retry
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        // Retry failed, continue to error handling
        developer.log('Retry failed', error: retryErr, name: 'DioInterceptor');
      }
    }
    
    // Convert to typed result
    final typedError = _convertToTypedError(err, errorType);
    final message = _extractMessage(typedError);
    
    // Create a new DioException with typed error
    final typedException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: typedError,
      message: message,
    );
    
    // Never crash - always pass a handled error
    handler.reject(typedException);
  }
  
  /// Generate unique fingerprint for request
  String _generateFingerprint(RequestOptions options) {
    final method = options.method;
    final uri = options.uri.toString();
    final body = options.data != null 
        ? jsonEncode(options.data).hashCode 
        : '';
    return '$method:$uri:$body';
  }
  
  /// Clean old fingerprints
  void _cleanOldFingerprints() {
    final now = DateTime.now();
    _requestFingerprints.removeWhere((_, timestamp) {
      return now.difference(timestamp) > FINGERPRINT_TTL;
    });
  }
  
  /// Classify error type
  NetworkResult<Never> _classifyError(DioException err) {
    final statusCode = err.response?.statusCode;
    
    // Network errors (no status code)
    if (statusCode == null) {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout) {
        return ServerUnavailable(
          message: 'Request timed out',
          retryable: true,
        );
      }
      if (err.type == DioExceptionType.connectionError) {
        return ServerUnavailable(
          message: 'No internet connection',
          retryable: true,
        );
      }
      return ServerUnavailable(
        message: 'Network error',
        retryable: true,
      );
    }
    
    // Permission errors (NEVER retry)
    switch (statusCode) {
      case 401:
        return PermissionDenied(
          statusCode: 401,
          message: 'Please log in again',
          detail: _extractDetail(err),
        );
      case 403:
        return PermissionDenied(
          statusCode: 403,
          message: 'You do not have permission',
          detail: _extractDetail(err),
        );
      case 409:
        return PermissionDenied(
          statusCode: 409,
          message: 'Chat room already closed',
          detail: _extractDetail(err),
        );
      case 410:
        return PermissionDenied(
          statusCode: 410,
          message: 'Chat expired or ended',
          detail: _extractDetail(err),
        );
    }
    
    // Server errors (retryable)
    if (statusCode >= 500 || statusCode == 503) {
      return ServerUnavailable(
        message: 'Service temporarily unavailable',
        retryable: true,
        retryAfter: DateTime.now().add(const Duration(seconds: 30)),
      );
    }
    
    // Other 4xx errors (client errors - don't retry)
    return PermissionDenied(
      statusCode: statusCode,
      message: _extractDetail(err) ?? 'Request failed',
      detail: _extractDetail(err),
    );
  }
  
  /// Determine if error should be retried
  bool _shouldRetry(DioException err, NetworkResult<Never> errorType) {
    // Never retry permission errors
    if (errorType is PermissionDenied) return false;
    
    // Retry server unavailable errors
    if (errorType is ServerUnavailable) {
      return errorType.retryable;
    }
    
    // Retry network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    
    return false;
  }
  
  /// Convert to typed error
  NetworkResult<Never> _convertToTypedError(
    DioException err,
    NetworkResult<Never> errorType,
  ) {
    return errorType;
  }
  
  /// Extract human-readable message from a typed error
  String _extractMessage(NetworkResult<Never> error) {
    if (error is PermissionDenied) return error.message;
    if (error is ServerUnavailable) return error.message;
    return 'Request failed';
  }
  
  /// Extract error detail from response
  String? _extractDetail(DioException err) {
    try {
      if (err.response?.data is Map) {
        final data = err.response!.data as Map;
        return data['detail'] as String?;
      }
      if (err.response?.data is String) {
        return err.response!.data as String;
      }
    } catch (_) {
      // Silently fail
    }
    return null;
  }
}

