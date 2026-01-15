/// Authentication-related constants
class AuthConstants {
  AuthConstants._();

  /// OAuth callback path for desktop authentication
  static const String oauthCallbackPath = '/callback';

  /// Timeout duration for OAuth flow (user has this long to complete sign-in)
  static const Duration oauthTimeout = Duration(minutes: 5);

  /// Delay before closing callback server after receiving response
  static const Duration callbackServerCloseDelay = Duration(seconds: 1);

  /// Provider name for Google authentication
  static const String googleProvider = 'google';
}
