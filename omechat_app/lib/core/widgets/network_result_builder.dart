/// Widget Builder for NetworkResult
/// 
/// Handles all NetworkResult states gracefully:
/// - LocalOnly: Shows data with offline indicator
/// - Synced: Shows data normally
/// - PendingSync: Shows data with pending indicator
/// - PermissionDenied: Shows friendly error message
/// - ServerUnavailable: Shows retry option or graceful degradation
import 'package:flutter/material.dart';
import '../network/network_result.dart';

typedef NetworkResultBuilder<T> = Widget Function(
  BuildContext context,
  T data,
  bool isOffline,
  bool isPending,
);

class NetworkResultWidget<T> extends StatelessWidget {
  final NetworkResult<T> result;
  final NetworkResultBuilder<T> builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(BuildContext, PermissionDenied)? permissionErrorBuilder;
  final Widget Function(BuildContext, ServerUnavailable)? serverErrorBuilder;

  const NetworkResultWidget({
    super.key,
    required this.result,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.permissionErrorBuilder,
    this.serverErrorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      Synced(data: final data) => builder(context, data, false, false),
      LocalOnly(data: final data) => builder(context, data, true, false),
      PendingSync(data: final data) => builder(context, data, false, true),
      PermissionDenied(:final message, :final statusCode) => 
        permissionErrorBuilder?.call(context, result as PermissionDenied) ??
        _defaultPermissionError(context, message, statusCode),
      ServerUnavailable(:final message) => 
        serverErrorBuilder?.call(context, result as ServerUnavailable) ??
        _defaultServerError(context, message),
    };
  }

  Widget _defaultPermissionError(BuildContext context, String message, int statusCode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (statusCode == 401 || statusCode == 403) ...[
              const SizedBox(height: 8),
              Text(
                'Please log in again or check your permissions',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultServerError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Offline Mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Showing cached data. Changes will sync when connection is restored.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

