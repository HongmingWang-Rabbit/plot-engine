import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app
/// Access environment variables through this class for type safety
class EnvConfig {
  /// API base URL for backend communication
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  /// App base URL (used for OAuth redirects, etc.)
  static String get appBaseUrl =>
      dotenv.env['APP_BASE_URL'] ?? 'https://plot-engine.com';

  /// Whether debug logging is enabled
  static bool get enableDebugLogging =>
      dotenv.env['ENABLE_DEBUG_LOGGING']?.toLowerCase() == 'true';

  /// Initialize environment configuration
  /// Call this before runApp() in main.dart
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }
}
