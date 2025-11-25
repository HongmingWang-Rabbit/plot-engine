import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';
import 'api_client.dart';

/// Google Sign In implementation of AuthService
/// Handles Google OAuth authentication flow and backend JWT verification
class GoogleAuthService implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For web, clientId is read from the HTML meta tag
    // For other platforms, use the native client ID
    clientId: kIsWeb
        ? null
        : '1049734729172-53ujfb8mlkkir19scv0v29ubrtubmfpu.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  final ApiClient _apiClient;
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  GoogleAuthService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        // Try to restore user from stored token
        await _restoreUser();
      } else {
        _currentUser = null;
        _authStateController.add(null);
      }
    });

    // Attempt to restore user on initialization
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
    try {
      // Step 1: Sign in with Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return AuthResult.failure('Sign in cancelled by user');
      }

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.idToken == null) {
        return AuthResult.failure('Failed to get Google ID token');
      }

      // Step 3: Verify with backend and get JWT token
      final response = await _apiClient.post('/auth/google/verify', {
        'idToken': auth.idToken,
        'platform': _getPlatform(),
      });

      if (response == null || response['token'] == null) {
        return AuthResult.failure('Backend verification failed');
      }

      // Step 4: Store JWT token
      final jwtToken = response['token'] as String;
      await _apiClient.setToken(jwtToken);

      // Step 5: Create and store user
      final user = _convertBackendUser(response['user'], jwtToken);
      _currentUser = user;
      _authStateController.add(user);

      return AuthResult.success(user);
    } catch (error) {
      if (error is ApiException) {
        return AuthResult.failure('Authentication failed: ${error.message}');
      }
      return AuthResult.failure('Google sign in failed: ${error.toString()}');
    }
  }

  @override
  Future<bool> signOut() async {
    try {
      await _googleSignIn.signOut();
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
      // Try to get fresh user data from backend
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

      // If that fails, try to get a new Google token
      final GoogleSignInAccount? account = _googleSignIn.currentUser;
      if (account == null) {
        return AuthResult.failure('No user signed in');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.idToken == null) {
        return AuthResult.failure('Failed to get Google ID token');
      }

      // Verify with backend again
      final verifyResponse = await _apiClient.post('/auth/google/verify', {
        'idToken': auth.idToken,
        'platform': _getPlatform(),
      });

      if (verifyResponse == null || verifyResponse['token'] == null) {
        return AuthResult.failure('Backend verification failed');
      }

      final jwtToken = verifyResponse['token'] as String;
      await _apiClient.setToken(jwtToken);

      final user = _convertBackendUser(verifyResponse['user'], jwtToken);
      _currentUser = user;
      _authStateController.add(user);

      return AuthResult.success(user);
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
      accessToken: jwtToken, // Store JWT as access token
      idToken: null,
      provider: 'google',
    );
  }

  /// Get platform identifier for backend
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  void dispose() {
    _authStateController.close();
  }
}
