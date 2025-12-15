/// Production-Grade Dio Error Interceptor
/// Handles retries, exponential backoff, and error conversion
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

class ProductionErrorInterceptor extends Interceptor {
  static const int MAX_RETRIES = 3;
  static const Duration INITIAL_BACKOFF = Duration(seconds: 1);
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Log all errors for debugging
    developer.log(
      'API Error: ${err.requestOptions.uri}',
      error: err,
      name: 'DioInterceptor',
      level: 900, // Error level
    );
    
    // Determine if this error is retryable
    final shouldRetry = _isRetryable(err);
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    if (shouldRetry && retryCount < MAX_RETRIES) {
      final newRetryCount = retryCount + 1;
      err.requestOptions.extra['retryCount'] = newRetryCount;
      
      // Exponential backoff: 1s, 2s, 4s
      final delay = INITIAL_BACKOFF * (1 << (newRetryCount - 1));
      
      developer.log(
        'Retrying request ($newRetryCount/$MAX_RETRIES) after ${delay.inSeconds}s',
        name: 'DioInterceptor',
      );
      
      await Future.delayed(delay);
      
      try {
        // Retry the request
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        // Retry failed, continue to error handling below
        developer.log('Retry failed', error: retryErr, name: 'DioInterceptor');
      }
    }
    
    // Convert to user-friendly error
    final appError = _convertToAppError(err);
    
    // Create a new DioException with user-friendly message
    final userFriendlyException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: appError,
      message: appError.message,
    );
    
    // Never crash - always pass a handled error
    handler.reject(userFriendlyException);
  }
  
  /// Determine if an error should be retried
  bool _isRetryable(DioException err) {
    // Retry on network/timeout errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    
    // Retry on 503 Service Unavailable (temporary backend issue)
    if (err.response?.statusCode == 503) {
      return true;
    }
    
    // Do NOT retry 4xx errors (client errors - user mistake)
    // Do NOT retry 500 errors (should be fixed in backend)
    return false;
  }
  
  /// Convert DioException to user-friendly AppError
  AppError _convertToAppError(DioException err) {
    final statusCode = err.response?.statusCode;
    
    // Handle network errors (no status code)
    if (statusCode == null) {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout) {
        return AppError(
          message: 'Request timed out. Please check your connection.',
          type: 'timeout',
          retryable: true,
        );
      }
      if (err.type == DioExceptionType.connectionError) {
        return AppError(
          message: 'No internet connection. Please check your network.',
          type: 'no_connection',
          retryable: true,
        );
      }
      return AppError(
        message: 'Network error. Please try again.',
        type: 'network_error',
        retryable: true,
      );
    }
    
    // Handle HTTP status codes
    switch (statusCode) {
      case 400:
        return AppError(
          message: _extractErrorMessage(err) ?? 'Invalid request',
          type: 'invalid_input',
          retryable: false,
        );
      case 401:
        return AppError(
          message: 'Please log in again',
          type: 'unauthorized',
          retryable: false,
        );
      case 403:
        return AppError(
          message: 'You do not have permission',
          type: 'forbidden',
          retryable: false,
        );
      case 404:
        return AppError(
          message: _extractErrorMessage(err) ?? 'Resource not found',
          type: 'not_found',
          retryable: false,
        );
      case 409:
        return AppError(
          message: _extractErrorMessage(err) ?? 'Duplicate or conflict detected',
          type: 'conflict',
          retryable: false,
        );
      case 503:
        return AppError(
          message: 'Service temporarily unavailable. Retrying...',
          type: 'service_unavailable',
          retryable: true,
        );
      default:
        // Treat all other errors as recoverable
        return AppError(
          message: 'Something went wrong. Please try again.',
          type: 'unknown',
          retryable: true,
        );
    }
  }
  
  /// Extract error message from backend response
  String? _extractErrorMessage(DioException err) {
    try {
      if (err.response?.data is Map) {
        final data = err.response!.data as Map;
        return data['detail'] as String?;
      }
    } catch (_) {
      // Silently fail - return null
    }
    return null;
  }
}

/// User-friendly error model
class AppError {
  final String message;
  final String type;
  final bool retryable;
  
  AppError({
    required this.message,
    required this.type,
    this.retryable = false,
  });
  
  @override
  String toString() => message;
}
