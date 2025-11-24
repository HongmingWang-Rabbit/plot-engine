import '../models/auth_user.dart';

/// Result of authentication operations
class AuthResult {
  final AuthUser? user;
  final String? error;
  final bool success;

  const AuthResult({
    this.user,
    this.error,
  }) : success = user != null && error == null;

  factory AuthResult.success(AuthUser user) {
    return AuthResult(user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult(error: error);
  }
}

/// Abstract base class for all authentication services
/// Implement this interface for each auth provider (Google, GitHub, Email, etc.)
abstract class AuthService {
  /// Returns the current authenticated user, if any
  AuthUser? get currentUser;

  /// Sign in with the provider's authentication flow
  /// Returns AuthResult with user on success or error message on failure
  Future<AuthResult> signIn();

  /// Sign out the current user
  /// Returns true on success, false on failure
  Future<bool> signOut();

  /// Refresh the current user's tokens
  /// Returns AuthResult with updated user on success or error message on failure
  Future<AuthResult> refreshToken();

  /// Check if user is currently signed in
  bool get isSignedIn => currentUser != null;

  /// Get the provider name (e.g., 'google', 'github', 'email')
  String get providerName;

  /// Stream of auth state changes
  /// Emits AuthUser when signed in, null when signed out
  Stream<AuthUser?> get authStateChanges;
}
