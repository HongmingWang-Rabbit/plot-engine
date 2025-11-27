import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app
/// Supports both compile-time (--dart-define) and runtime (.env file) configuration
/// Compile-time values take precedence over .env file values
class EnvConfig {
  // Compile-time constants from --dart-define
  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _appBaseUrlDefine = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: '',
  );
  static const bool _enableDebugLoggingDefine = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: false,
  );

  /// API base URL for backend communication
  /// Priority: --dart-define > .env > default
  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) return _apiBaseUrlDefine;
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  }

  /// App base URL (used for OAuth redirects, etc.)
  /// Priority: --dart-define > .env > default
  static String get appBaseUrl {
    if (_appBaseUrlDefine.isNotEmpty) return _appBaseUrlDefine;
    return dotenv.env['APP_BASE_URL'] ?? 'https://plot-engine.com';
  }

  /// Whether debug logging is enabled
  static bool get enableDebugLogging {
    if (_enableDebugLoggingDefine) return true;
    return dotenv.env['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';
  }

  /// Whether running in production mode
  static bool get isProduction => kReleaseMode;

  /// Initialize environment configuration
  /// Call this before runApp() in main.dart
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file may not exist in production builds using --dart-define
      debugPrint('[EnvConfig] .env file not found, using compile-time values');
    }
  }
}
