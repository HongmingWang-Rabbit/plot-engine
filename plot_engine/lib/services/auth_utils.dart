import '../models/auth_user.dart';

/// Shared utilities for authentication services
class AuthUtils {
  AuthUtils._();

  /// Convert backend user response to AuthUser model
  /// Used by all auth service implementations
  static AuthUser convertBackendUser(
    Map<String, dynamic> backendUser,
    String jwtToken,
  ) {
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
}
