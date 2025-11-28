import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _penController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _typewriterController;

  // Animations
  late Animation<double> _penAnimation;
  late Animation<double> _logoFade;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  // Typewriter
  String _displayedSubtitle = '';
  static const String _fullSubtitle = 'Your AI-powered writing companion';

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Pen drawing animation - continuous loop
    _penController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _penAnimation = CurvedAnimation(
      parent: _penController,
      curve: Curves.easeInOut,
    );

    // Fade in animations for UI elements
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Typewriter animation
    _typewriterController = AnimationController(
      duration: Duration(milliseconds: _fullSubtitle.length * 50),
      vsync: this,
    );

    _typewriterController.addListener(() {
      final charCount =
          (_typewriterController.value * _fullSubtitle.length).floor();
      if (_displayedSubtitle.length != charCount) {
        setState(() {
          _displayedSubtitle = _fullSubtitle.substring(0, charCount);
        });
      }
    });

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _typewriterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _penController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authNotifier = ref.read(authUserProvider.notifier);
    final result = await authNotifier.signIn();

    // Don't update state if redirecting (page will navigate away)
    if (result.error?.contains('Redirecting') == true) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!result.success) {
      setState(() {
        _errorMessage = result.error ?? 'Sign in failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
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
          ),

          // Floating ink particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: InkParticlesPainter(
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Writing lines animation
          AnimatedBuilder(
            animation: _penAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: WritingLinesPainter(
                  progress: _penAnimation.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(32),
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated pen/quill logo
                        FadeTransition(
                          opacity: _logoFade,
                          child: _buildAnimatedLogo(),
                        ),

                        const SizedBox(height: 32),

                        // Title with shimmer effect
                        FadeTransition(
                          opacity: _titleFade,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.indigo.shade700,
                                  Colors.indigo.shade500,
                                  Colors.purple.shade400,
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'PlotEngine',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Typewriter subtitle
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: SizedBox(
                            height: 24,
                            child: Text(
                              '$_displayedSubtitle${_displayedSubtitle.length < _fullSubtitle.length ? '|' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Card with sign-in button
                        SlideTransition(
                          position: _buttonSlide,
                          child: FadeTransition(
                            opacity: _buttonFade,
                            child: _buildSignInCard(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _penController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.indigo.shade100.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              Transform.rotate(
                angle: _penController.value * 2 * pi,
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: OrbitingDotsPainter(
                    progress: _penController.value,
                  ),
                ),
              ),
              // Animated pen icon
              Transform.rotate(
                angle: sin(_penController.value * 2 * pi) * 0.1,
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 56,
                  color: Colors.indigo.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignInCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Google Sign In Button
            _buildGoogleButton(),

            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'More options coming soon',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[800],
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.indigo.shade400,
                  ),
                )
              else ...[
                // Google "G" logo approximation
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Text(
                _isLoading ? 'Signing in...' : 'Continue with Google',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for floating ink particles
class InkParticlesPainter extends CustomPainter {
  final double progress;
  final List<_InkParticle> _particles;

  InkParticlesPainter({required this.progress})
      : _particles = List.generate(15, (i) => _InkParticle(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final x = (particle.startX + progress * particle.speedX) % 1.0 * size.width;
      final y = (particle.startY + progress * particle.speedY) % 1.0 * size.height;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant InkParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _InkParticle {
  final double startX;
  final double startY;
  final double speedX;
  final double speedY;
  final double size;
  final double opacity;
  final Color color;

  _InkParticle(int seed)
      : startX = _seededRandom(seed * 7) ,
        startY = _seededRandom(seed * 13),
        speedX = _seededRandom(seed * 17) * 0.3 + 0.1,
        speedY = _seededRandom(seed * 23) * 0.2 + 0.05,
        size = _seededRandom(seed * 31) * 4 + 2,
        opacity = _seededRandom(seed * 37) * 0.5 + 0.3,
        color = [
          Colors.indigo.shade300,
          Colors.purple.shade200,
          Colors.blue.shade200,
          Colors.amber.shade200,
        ][seed % 4];

  static double _seededRandom(int seed) {
    return ((sin(seed.toDouble()) * 43758.5453) % 1).abs();
  }
}

// Custom painter for writing lines animation
class WritingLinesPainter extends CustomPainter {
  final double progress;

  WritingLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw animated writing lines
    for (int i = 0; i < 5; i++) {
      final yOffset = size.height * 0.3 + i * 40;
      final lineProgress = ((progress + i * 0.2) % 1.0);

      final path = Path();
      final startX = size.width * 0.1;
      final endX = size.width * 0.9 * lineProgress;

      path.moveTo(startX, yOffset);

      // Create a slightly wavy line to simulate handwriting
      for (double x = startX; x < startX + (endX - startX); x += 5) {
        final waveY = sin(x * 0.05 + progress * 10) * 2;
        path.lineTo(x, yOffset + waveY);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WritingLinesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Custom painter for orbiting dots around the logo
class OrbitingDotsPainter extends CustomPainter {
  final double progress;

  OrbitingDotsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * pi + (i * 2 * pi / 3);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final paint = Paint()
        ..color = [
          Colors.indigo.shade400,
          Colors.purple.shade300,
          Colors.amber.shade400,
        ][i]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitingDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
