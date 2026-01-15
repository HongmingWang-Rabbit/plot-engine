import 'dart:async';
import '../models/auth_user.dart';
import 'auth_service.dart';

/// Stub implementation of DesktopAuthService for web platform.
/// This file is imported on web to avoid dart:io errors.
class DesktopAuthService implements AuthService {
  DesktopAuthService();

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
    return AuthResult.failure('Desktop auth not supported on this platform');
  }

  @override
  Future<bool> signOut() async {
    return false;
  }

  @override
  Future<AuthResult> refreshToken() async {
    return AuthResult.failure('Desktop auth not supported on this platform');
  }

  void dispose() {}
}
