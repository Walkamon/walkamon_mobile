import 'package:flutter/material.dart';

class DewdropIcon extends StatelessWidget {
  const DewdropIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DewdropPainter(
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _DewdropPainter extends CustomPainter {
  const _DewdropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.104)
      ..cubicTo(
        size.width * 0.8125,
        size.height * 0.396,
        size.width * 0.8125,
        size.height * 0.729,
        size.width * 0.5,
        size.height * 0.896,
      )
      ..cubicTo(
        size.width * 0.1875,
        size.height * 0.729,
        size.width * 0.1875,
        size.height * 0.396,
        size.width * 0.5,
        size.height * 0.104,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DewdropPainter oldDelegate) => oldDelegate.color != color;
}
