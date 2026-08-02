import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fixed game wordmark shared by the welcome and authentication screens.
class GameWordmark extends StatelessWidget {
  const GameWordmark({
    super.key,
    required this.title,
    required this.tagline,
    this.width = 310,
  });

  final String title;
  final String tagline;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = width / 310;
    final leafColor = isDark ? AppColors.darkPrimary : AppColors.leafBright;
    final outerStroke = isDark ? AppColors.darkForeground : AppColors.ivory;
    final innerStroke = isDark ? AppColors.olive : AppColors.oliveDeep;

    return Semantics(
      container: true,
      label: '$title. $tagline',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: width * 0.52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(width, width),
                painter: _GameWordmarkPainter(
                  leafColor: leafColor,
                  sparkleColor: outerStroke,
                  strokeColor: innerStroke,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 14 * scale),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _outlinedText(
                      text: title,
                      fontSize: 43 * scale,
                      fillColor: AppColors.goldLight,
                      innerStroke: innerStroke,
                      outerStroke: outerStroke,
                      outerWidth: 10 * scale,
                      innerWidth: 5.5 * scale,
                      letterSpacing: -1.4 * scale,
                    ),
                    SizedBox(height: 2 * scale),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width * 0.84),
                      child: _outlinedText(
                        text: tagline,
                        fontSize: 19 * scale,
                        fillColor: AppColors.leafLight,
                        innerStroke: innerStroke,
                        outerStroke: outerStroke,
                        outerWidth: 7 * scale,
                        innerWidth: 3.8 * scale,
                        letterSpacing: 0.1 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlinedText({
    required String text,
    required double fontSize,
    required Color fillColor,
    required Color innerStroke,
    required Color outerStroke,
    required double outerWidth,
    required double innerWidth,
    required double letterSpacing,
  }) {
    TextStyle style({Color? color, Paint? foreground}) => TextStyle(
      color: color,
      foreground: foreground,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 0.96,
      letterSpacing: letterSpacing,
    );

    Text layer(TextStyle textStyle) => Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.visible,
      style: textStyle,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        layer(
          style(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = outerWidth
              ..color = outerStroke,
          ),
        ),
        layer(
          style(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = innerWidth
              ..color = innerStroke,
          ),
        ),
        layer(
          style(color: fillColor).copyWith(
            shadows: const [
              Shadow(
                color: Color(0x55352318),
                blurRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameWordmarkPainter extends CustomPainter {
  const _GameWordmarkPainter({
    required this.leafColor,
    required this.sparkleColor,
    required this.strokeColor,
  });

  final Color leafColor;
  final Color sparkleColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas
      ..save()
      ..scale(scale);

    final fillPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final stem = Path()
      ..moveTo(84, 22)
      ..quadraticBezierTo(84, 17, 81, 14);
    canvas.drawPath(stem, strokePaint);

    final leftLeaf = Path()
      ..moveTo(83, 18)
      ..cubicTo(75, 18, 74, 11, 81, 11)
      ..cubicTo(85, 12, 85, 15, 83, 18)
      ..close();
    canvas
      ..drawPath(leftLeaf, fillPaint)
      ..drawPath(leftLeaf, strokePaint);

    final rightLeaf = Path()
      ..moveTo(84, 17)
      ..cubicTo(86, 10, 94, 10, 92, 16)
      ..cubicTo(90, 20, 86, 20, 84, 17)
      ..close();
    canvas
      ..drawPath(rightLeaf, fillPaint)
      ..drawPath(rightLeaf, strokePaint);

    _drawSparkle(canvas, const Offset(18, 17));
    _drawSparkle(canvas, const Offset(73, 7));
    _drawSparkle(canvas, const Offset(96, 27));
    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center) {
    final path = Path()
      ..moveTo(center.dx, center.dy - 3)
      ..lineTo(center.dx + 3, center.dy)
      ..lineTo(center.dx, center.dy + 3)
      ..lineTo(center.dx - 3, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = sparkleColor);
  }

  @override
  bool shouldRepaint(covariant _GameWordmarkPainter oldDelegate) {
    return oldDelegate.leafColor != leafColor ||
        oldDelegate.sparkleColor != sparkleColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
