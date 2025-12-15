/// Typed Network Result - Never throw raw exceptions
///
/// All network operations return a Result type that encapsulates
/// success, failure, and state information.
sealed class NetworkResult<T> {}

class Synced<T> extends NetworkResult<T> {
  final T data;
  final DateTime syncedAt;
  
  Synced(this.data, {DateTime? syncedAt})
      : syncedAt = syncedAt ?? DateTime.now();
}

class LocalOnly<T> extends NetworkResult<T> {
  final T data;
  final DateTime cachedAt;
  
  LocalOnly(this.data, {DateTime? cachedAt})
      : cachedAt = cachedAt ?? DateTime.now();
}

class PendingSync<T> extends NetworkResult<T> {
  final T data;
  final DateTime pendingSince;
  
  PendingSync(this.data, {DateTime? pendingSince})
      : pendingSince = pendingSince ?? DateTime.now();
}

class PermissionDenied extends NetworkResult<Never> {
  final int statusCode;
  final String message;
  final String? detail;
  
  PermissionDenied({
    required this.statusCode,
    required this.message,
    this.detail,
  });
}

class ServerUnavailable extends NetworkResult<Never> {
  final String message;
  final bool retryable;
  final DateTime? retryAfter;
  
  ServerUnavailable({
    required this.message,
    this.retryable = true,
    this.retryAfter,
  });
}

/// Extension to extract data from any result
extension NetworkResultExtension<T> on NetworkResult<T> {
  T? get dataOrNull {
    return switch (this) {
      Synced(data: final d) => d,
      LocalOnly(data: final d) => d,
      PendingSync(data: final d) => d,
      PermissionDenied() => null,
      ServerUnavailable() => null,
    };
  }
  
  bool get hasData => dataOrNull != null;
  
  bool get isSynced => this is Synced;
  
  bool get isLocalOnly => this is LocalOnly;
  
  bool get isPendingSync => this is PendingSync;
  
  bool get isError => this is PermissionDenied || this is ServerUnavailable;
}

