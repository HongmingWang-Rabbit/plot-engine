import 'package:flutter/material.dart';

/// Screen that handles OAuth callback errors
class AuthErrorScreen extends StatelessWidget {
  final String? error;
  final String? message;

  const AuthErrorScreen({
    super.key,
    this.error,
    this.message,
  });

  String get errorMessage {
    switch (error) {
      case 'oauth_failed':
        return 'Google sign-in was cancelled or failed';
      case 'no_code':
        return 'Authentication error: no authorization code received';
      case 'token_exchange_failed':
        return message ?? 'Failed to complete authentication';
      default:
        return message ?? 'An unknown error occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Authentication Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error code: $error',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
