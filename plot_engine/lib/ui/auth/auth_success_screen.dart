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

class _AuthSuccessScreenState extends ConsumerState<AuthSuccessScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  String? _error;
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _handleToken();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.white,
              Colors.amber.shade50,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_error == null) ...[
                      // Success state - friendly indigo theme
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.indigo.shade100,
                              Colors.indigo.shade50,
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.indigo.shade400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Colors.indigo.shade600,
                              Colors.purple.shade400,
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Taking you to PlotEngine...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      // Error state - softer amber/orange theme instead of red
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.shade50,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 40,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/');
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back to Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
