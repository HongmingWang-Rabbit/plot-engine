import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/auth_user.dart';
import '../config/env_config.dart';
import '../core/constants/auth_constants.dart';
import 'auth_service.dart';
import 'auth_utils.dart';
import 'api_client.dart';

/// Desktop-specific auth service that uses browser-based OAuth flow.
/// Opens the system browser for Google OAuth and receives the callback
/// via a local HTTP server.
class DesktopAuthService implements AuthService {
  final ApiClient _apiClient;
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  HttpServer? _callbackServer;
  Completer<String?>? _tokenCompleter;

  DesktopAuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _restoreUser();
  }

  /// Restore user from stored JWT token
  Future<void> _restoreUser() async {
    try {
      final token = await _apiClient.getToken();
      if (token != null) {
        // Verify token with backend
        final response = await _apiClient.get('/auth/me');
        if (response != null && response['user'] != null) {
          _currentUser = AuthUtils.convertBackendUser(response['user'], token);
          _authStateController.add(_currentUser);
          return;
        }
      }
    } catch (e) {
      // Token invalid or expired, clear it
      await _apiClient.clearToken();
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  String get providerName => AuthConstants.googleProvider;

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  bool get isSignedIn => _currentUser != null;

  @override
  Future<AuthResult> signIn() async {
    try {
      // Start local server to receive OAuth callback
      final token = await _startOAuthFlow();

      if (token == null) {
        return AuthResult.failure('Sign in cancelled or failed');
      }

      // Store the token
      await _apiClient.setToken(token);

      // Get user info from backend
      final response = await _apiClient.get('/auth/me');
      if (response != null && response['user'] != null) {
        final user = AuthUtils.convertBackendUser(response['user'], token);
        _currentUser = user;
        _authStateController.add(user);
        return AuthResult.success(user);
      }

      return AuthResult.failure('Failed to get user info');
    } catch (error) {
      return AuthResult.failure('Sign in failed: ${error.toString()}');
    }
  }

  /// Start the OAuth flow by opening browser and listening for callback
  Future<String?> _startOAuthFlow() async {
    // Start local HTTP server on an available port
    _callbackServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = _callbackServer!.port;
    final redirectUri = 'http://localhost:$port/callback';

    _tokenCompleter = Completer<String?>();

    // Listen for the callback
    _callbackServer!.listen((request) async {
      if (request.uri.path == AuthConstants.oauthCallbackPath) {
        final token = request.uri.queryParameters['token'];
        final error = request.uri.queryParameters['error'];

        // Send response to browser
        request.response.headers.contentType = ContentType.html;
        if (token != null) {
          request.response.write(_successHtml);
        } else {
          request.response.write(_errorHtml(error ?? 'Unknown error'));
        }
        await request.response.close();

        // Complete the flow
        if (!_tokenCompleter!.isCompleted) {
          _tokenCompleter!.complete(token);
        }

        // Cleanup server after short delay
        Future.delayed(AuthConstants.callbackServerCloseDelay, () {
          _callbackServer?.close();
          _callbackServer = null;
        });
      }
    });

    // Open browser for OAuth
    final apiBaseUrl = EnvConfig.apiBaseUrl;
    final authUrl = Uri.parse('$apiBaseUrl/auth/google?redirect=${Uri.encodeComponent(redirectUri)}');

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      _tokenCompleter?.complete(null);
      _callbackServer?.close();
      throw Exception('Could not open browser for authentication');
    }

    // Wait for callback with timeout
    try {
      final token = await _tokenCompleter!.future.timeout(
        AuthConstants.oauthTimeout,
        onTimeout: () {
          _callbackServer?.close();
          return null;
        },
      );
      return token;
    } catch (e) {
      _callbackServer?.close();
      return null;
    }
  }

  @override
  Future<bool> signOut() async {
    try {
      await _apiClient.clearToken();
      _currentUser = null;
      _authStateController.add(null);
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response != null && response['user'] != null) {
        final token = await _apiClient.getToken();
        if (token != null) {
          final user = AuthUtils.convertBackendUser(response['user'], token);
          _currentUser = user;
          _authStateController.add(user);
          return AuthResult.success(user);
        }
      }
      return AuthResult.failure('No valid token');
    } catch (error) {
      return AuthResult.failure('Token refresh failed: ${error.toString()}');
    }
  }

  void dispose() {
    _callbackServer?.close();
    _authStateController.close();
  }

  static const String _successHtml = '''
<!DOCTYPE html>
<html>
<head>
  <title>Sign In Successful</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 16px;
      backdrop-filter: blur(10px);
    }
    h1 { margin-bottom: 16px; }
    p { opacity: 0.9; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Sign In Successful!</h1>
    <p>You can close this window and return to PlotEngine.</p>
  </div>
</body>
</html>
''';

  static String _errorHtml(String error) => '''
<!DOCTYPE html>
<html>
<head>
  <title>Sign In Failed</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
      color: white;
    }
    .container {
      text-align: center;
      padding: 40px;
      background: rgba(255,255,255,0.1);
      border-radius: 16px;
      backdrop-filter: blur(10px);
    }
    h1 { margin-bottom: 16px; }
    p { opacity: 0.9; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Sign In Failed</h1>
    <p>Error: $error</p>
    <p>Please close this window and try again.</p>
  </div>
</body>
</html>
''';
}
