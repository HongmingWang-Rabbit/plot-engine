import 'package:flutter/foundation.dart';

/// Centralized logging service
class AppLogger {
  /// Log debug messages (only in debug mode)
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[DEBUG] $message${data != null ? ': $data' : ''}');
    }
  }

  /// Log info messages
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[INFO] $message${data != null ? ': $data' : ''}');
    }
  }

  /// Log warning messages
  static void warn(String message, [dynamic data]) {
    if (kDebugMode) {
      print('[WARN] $message${data != null ? ': $data' : ''}');
    }
  }

  /// Log error messages
  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      print('[ERROR] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
    // TODO: Send to crash reporting service (Sentry, Firebase, etc.)
  }

  /// Log save operations
  static void save(String operation, {int? itemCount, String? path}) {
    if (kDebugMode) {
      final details = [
        if (itemCount != null) '$itemCount items',
        if (path != null) 'to: $path',
      ].join(', ');
      print('💾 $operation${details.isNotEmpty ? ' ($details)' : ''}');
    }
  }

  /// Log load operations
  static void load(String operation, {int? itemCount, String? path}) {
    if (kDebugMode) {
      final details = [
        if (itemCount != null) '$itemCount items',
        if (path != null) 'from: $path',
      ].join(', ');
      print('📂 $operation${details.isNotEmpty ? ' ($details)' : ''}');
    }
  }
}

/// Error handling utilities
class ErrorHandler {
  /// Handle sync operation with error logging
  static T? handleSync<T>(
    T Function() operation,
    String context,
  ) {
    try {
      return operation();
    } catch (error, stackTrace) {
      AppLogger.error(context, error, stackTrace);
      return null;
    }
  }

  /// Handle async operation with error logging
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation,
    String context,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      AppLogger.error(context, error, stackTrace);
      return null;
    }
  }

  /// Handle async operation with custom error callback
  static Future<T?> handleAsyncWithCallback<T>(
    Future<T> Function() operation,
    String context, {
    Function(dynamic error)? onError,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      AppLogger.error(context, error, stackTrace);
      onError?.call(error);
      return null;
    }
  }
}
