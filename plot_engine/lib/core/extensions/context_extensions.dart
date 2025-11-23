import 'package:flutter/material.dart';

/// Safe context extensions for common async operations
extension SafeContext on BuildContext {
  /// Show snackbar only if context is still mounted
  void showSnackBarIfMounted(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
        duration: duration,
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    showSnackBarIfMounted(message, isError: false);
  }

  /// Show error snackbar
  void showError(String message) {
    showSnackBarIfMounted(message, isError: true);
  }

  /// Show dialog only if context is still mounted
  Future<T?> showDialogIfMounted<T>(WidgetBuilder builder) async {
    if (!mounted) return null;
    return showDialog<T>(context: this, builder: builder);
  }

  /// Navigate only if context is still mounted
  Future<T?> pushIfMounted<T>(Route<T> route) async {
    if (!mounted) return null;
    return Navigator.of(this).push(route);
  }

  /// Pop only if context is still mounted
  void popIfMounted<T>([T? result]) {
    if (!mounted) return;
    Navigator.of(this).pop(result);
  }
}

/// Theme access shortcuts
extension ThemeExtensions on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get primaryColor => colors.primary;
  Color get surfaceColor => colors.surface;
  Color get errorColor => colors.error;

  /// Get faded onSurface color
  Color fadedOnSurface([double opacity = 0.6]) =>
      colors.onSurface.withValues(alpha: opacity);
}
