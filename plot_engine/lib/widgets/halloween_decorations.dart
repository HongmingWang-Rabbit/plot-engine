import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Halloween-themed decorative widget that adds floating pumpkins and ghosts
class HalloweenDecorations extends StatefulWidget {
  final Widget child;

  const HalloweenDecorations({
    super.key,
    required this.child,
  });

  @override
  State<HalloweenDecorations> createState() => _HalloweenDecorationsState();
}

class _HalloweenDecorationsState extends State<HalloweenDecorations>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Floating decorations
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: HalloweenPainter(_controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class HalloweenPainter extends CustomPainter {
  final double animationValue;
  final math.Random random = math.Random(42); // Fixed seed for consistency

  HalloweenPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle floating pumpkins and ghosts
    for (int i = 0; i < 5; i++) {
      final x = (random.nextDouble() * size.width);
      final baseY = (random.nextDouble() * size.height);
      final y = baseY + math.sin(animationValue * 2 * math.pi + i) * 20;
      final opacity = 0.05 + (math.sin(animationValue * 2 * math.pi + i) * 0.02);

      if (i % 2 == 0) {
        _drawPumpkin(canvas, Offset(x, y), opacity);
      } else {
        _drawGhost(canvas, Offset(x, y), opacity);
      }
    }
  }

  void _drawPumpkin(Canvas canvas, Offset position, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B00).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Pumpkin body
    canvas.drawCircle(position, 15, paint);

    // Pumpkin eyes (darker orange)
    final eyePaint = Paint()
      ..color = const Color(0xFF8B4000).withValues(alpha: opacity * 1.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position + const Offset(-5, -3), 2, eyePaint);
    canvas.drawCircle(position + const Offset(5, -3), 2, eyePaint);

    // Pumpkin mouth
    final path = Path()
      ..moveTo(position.dx - 6, position.dy + 3)
      ..quadraticBezierTo(position.dx, position.dy + 6, position.dx + 6, position.dy + 3);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8B4000).withValues(alpha: opacity * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawGhost(Canvas canvas, Offset position, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFE8D5FF).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Ghost body (rounded top, wavy bottom)
    final path = Path()
      ..moveTo(position.dx, position.dy - 15)
      ..quadraticBezierTo(position.dx - 10, position.dy - 15, position.dx - 10, position.dy - 5)
      ..lineTo(position.dx - 10, position.dy + 10)
      ..quadraticBezierTo(position.dx - 7, position.dy + 15, position.dx - 4, position.dy + 10)
      ..quadraticBezierTo(position.dx, position.dy + 15, position.dx + 4, position.dy + 10)
      ..quadraticBezierTo(position.dx + 7, position.dy + 15, position.dx + 10, position.dy + 10)
      ..lineTo(position.dx + 10, position.dy - 5)
      ..quadraticBezierTo(position.dx + 10, position.dy - 15, position.dx, position.dy - 15);

    canvas.drawPath(path, paint);

    // Ghost eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF1A0F1F).withValues(alpha: opacity * 2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position + const Offset(-4, -5), 2, eyePaint);
    canvas.drawCircle(position + const Offset(4, -5), 2, eyePaint);
  }

  @override
  bool shouldRepaint(HalloweenPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Spooky text style for Halloween theme
class SpookyText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SpookyText(
    this.text, {
    super.key,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
        shadows: [
          Shadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}
