import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Environment configuration for the app
/// Loads from config.json at runtime (editable without rebuilding)
///
/// Config file location: web/config.json
class EnvConfig {
  static Map<String, dynamic> _config = {};

  // Defaults
  static const String _defaultApiBaseUrl = 'https://api.plot-engine.com';
  static const String _defaultAppBaseUrl = 'https://plot-engine.com';

  /// API base URL for backend communication
  static String get apiBaseUrl =>
      _config['apiBaseUrl'] as String? ?? _defaultApiBaseUrl;

  /// App base URL (used for OAuth redirects, etc.)
  static String get appBaseUrl =>
      _config['appBaseUrl'] as String? ?? _defaultAppBaseUrl;

  /// Whether debug logging is enabled
  static bool get enableDebugLogging =>
      _config['enableDebugLogging'] as bool? ?? false;

  /// Whether running in production mode
  static bool get isProduction => kReleaseMode;

  /// Initialize configuration from config.json
  static Future<void> init() async {
    try {
      // For web, config.json is in the web root
      final response = await http.get(Uri.parse('config.json'));
      if (response.statusCode == 200) {
        _config = json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Config file not found or invalid - use defaults silently
      _config = {};
    }
  }
}
