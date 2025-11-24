/// Abstract representation of an authenticated user
/// This model is provider-agnostic and can be implemented by different auth providers
class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken;
  final String? idToken;
  final String provider; // 'google', 'github', 'email', etc.

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    required this.provider,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'idToken': idToken,
      'provider': provider,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      accessToken: json['accessToken'] as String?,
      idToken: json['idToken'] as String?,
      provider: json['provider'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          provider == other.provider;

  @override
  int get hashCode => id.hashCode ^ provider.hashCode;

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, provider: $provider)';
  }
}
