import 'dart:async';
import '../models/auth_user.dart';
import 'auth_service.dart';

/// Stub implementation of WebAuthService for non-web platforms.
/// This file is imported on desktop/mobile platforms to avoid dart:html errors.
class WebAuthService implements AuthService {
  WebAuthService();

  @override
  AuthUser? get currentUser => null;

  @override
  String get providerName => 'google';

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  bool get isSignedIn => false;

  @override
  Future<AuthResult> signIn() async {
    return AuthResult.failure('Web auth not supported on this platform');
  }

  @override
  Future<bool> signOut() async {
    return false;
  }

  @override
  Future<AuthResult> refreshToken() async {
    return AuthResult.failure('Web auth not supported on this platform');
  }

  void dispose() {}
}
