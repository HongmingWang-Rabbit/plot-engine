import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';
import '../../core/utils/logger.dart';
import '../../utils/web_url_helper.dart' if (dart.library.io) '../../utils/web_url_helper_stub.dart';
import 'login_screen.dart';

/// Screen that handles OAuth callback success
/// Receives JWT token from URL and saves it
class AuthSuccessScreen extends ConsumerStatefulWidget {
  final String? token;

  const AuthSuccessScreen({super.key, this.token});

  @override
  ConsumerState<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends ConsumerState<AuthSuccessScreen> {
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleToken();
  }

  Future<void> _handleToken() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final token = widget.token;

      AppLogger.debug('AuthSuccess: Processing token');

      if (token == null || token.isEmpty) {
        AppLogger.debug('AuthSuccess: No token, redirecting to home');
        // No token - likely duplicate request, just reload page
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && kIsWeb) {
          // For web, just reload to home
          reloadPage();
        } else if (mounted) {
          // For native, navigate
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      // Save token using API client
      AppLogger.debug('AuthSuccess: Saving token');
      final apiClient = ref.read(apiClientProvider);
      await apiClient.setToken(token);

      // Get user info to verify token
      AppLogger.debug('AuthSuccess: Verifying token');
      final response = await apiClient.get('/auth/me');

      if (response != null && response['user'] != null) {
        AppLogger.debug('AuthSuccess: User verified, refreshing auth state');
        // Trigger auth state refresh
        await ref.read(authUserProvider.notifier).refreshToken();

        // Wait a moment before redirecting
        await Future.delayed(const Duration(milliseconds: 500));

        AppLogger.debug('AuthSuccess: Navigating to home');
        if (mounted && kIsWeb) {
          // For web, reload the page to clear URL and reinitialize with auth state
          reloadPage();
        } else if (mounted) {
          // For native, use navigator
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => SizedBox.shrink()),
            (route) => false,
          );
        }
      } else {
        throw Exception('Failed to verify token - no user data');
      }
    } catch (e, stackTrace) {
      AppLogger.error('AuthSuccess: Error', e, stackTrace);
      setState(() {
        _error = e.toString();
      });
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
              if (_error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Authentication successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Redirecting to PlotEngine...',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Authentication Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  child: const Text('Back to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
