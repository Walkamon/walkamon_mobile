import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class SproutLogo extends StatefulWidget {
  const SproutLogo({super.key, this.size = 96});

  final double size;

  @override
  State<SproutLogo> createState() => _SproutLogoState();
}

class _SproutLogoState extends State<SproutLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor =
        isDark ? AppColors.darkLuminaGlow : AppColors.lightLuminaGlow;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _bounce,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounce.value),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _SproutPainter(glowColor: glowColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({required this.glowColor});

  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale);

    final glowPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;

    // Stem
    final stem = Path()
      ..moveTo(50, 90)
      ..quadraticBezierTo(50, 60, 40, 45);
    canvas.drawPath(stem, glowPaint);

    // Left leaf
    final leftLeaf = Path()
      ..moveTo(40, 45)
      ..cubicTo(20, 40, 20, 60, 40, 55)
      ..close();
    canvas.drawPath(leftLeaf, fillPaint);

    // Right leaf
    final rightLeaf = Path()
      ..moveTo(42, 50)
      ..cubicTo(65, 40, 70, 20, 50, 35)
      ..close();
    canvas.drawPath(rightLeaf, fillPaint);

    // Center orb
    canvas.drawCircle(const Offset(50, 85), 10, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(50, 85), 5, fillPaint);

    // Sparkles
    _drawSparkle(canvas, const Offset(30, 25), Colors.white);
    _drawSparkle(canvas, const Offset(80, 60), Colors.white);

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 5)
      ..lineTo(center.dx + 5, center.dy)
      ..lineTo(center.dx, center.dy + 5)
      ..lineTo(center.dx - 5, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SproutPainter oldDelegate) =>
      oldDelegate.glowColor != glowColor;
}
