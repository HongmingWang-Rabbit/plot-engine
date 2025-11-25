import 'dart:async';
import 'dart:html' as html;
import '../models/auth_user.dart';
import 'auth_service.dart';
import 'api_client.dart';

/// Web-specific auth service that uses backend OAuth flow
/// Redirects to backend for Google authentication
class WebAuthService implements AuthService {
  static const String backendUrl = 'http://localhost:3000';

  final ApiClient _apiClient;
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  WebAuthService({ApiClient? apiClient})
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
          _currentUser = _convertBackendUser(response['user'], token);
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
  String get providerName => 'google';

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  bool get isSignedIn => _currentUser != null;

  @override
  Future<AuthResult> signIn() async {
    // For web, redirect to backend OAuth flow
    // The backend will handle Google OAuth and redirect back with a token
    final currentUrl = html.window.location.href;
    final redirectUrl = Uri.encodeComponent(currentUrl);

    // Redirect to backend OAuth endpoint
    html.window.location.href = '$backendUrl/auth/google?redirect=$redirectUrl';

    // This won't actually return since we're redirecting
    return AuthResult.failure('Redirecting to Google Sign-In...');
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
          final user = _convertBackendUser(response['user'], token);
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

  /// Convert backend user response to AuthUser
  AuthUser _convertBackendUser(Map<String, dynamic> backendUser, String jwtToken) {
    return AuthUser(
      id: backendUser['id'] as String,
      email: backendUser['email'] as String?,
      displayName: backendUser['displayName'] as String?,
      photoUrl: backendUser['avatarUrl'] as String?,
      accessToken: jwtToken,
      idToken: null,
      provider: 'google',
    );
  }

  /// Handle OAuth callback (call this when redirected back from backend)
  /// Pass the token from the URL query parameter
  Future<AuthResult> handleCallback(String token) async {
    try {
      // Store the token
      await _apiClient.setToken(token);

      // Get user info
      final response = await _apiClient.get('/auth/me');
      if (response != null && response['user'] != null) {
        final user = _convertBackendUser(response['user'], token);
        _currentUser = user;
        _authStateController.add(user);
        return AuthResult.success(user);
      }

      return AuthResult.failure('Failed to get user info');
    } catch (error) {
      return AuthResult.failure('Callback handling failed: ${error.toString()}');
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
