import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import '../../core/motion/motion_tokens.dart';

/// Small bounded Flame effect, using the parent's normalized pet anchor.
/// No asset tint, no per-particle widgets, no gameplay mutations.
class LuminaVfxLayer extends StatefulWidget {
  const LuminaVfxLayer({
    super.key,
    required this.progress,
    this.anchor = const Offset(0.5, 0.58),
    this.color = const Color(0xFFE8BC57),
  });
  final double progress;
  final Offset anchor;
  final Color color;

  @override
  State<LuminaVfxLayer> createState() => _LuminaVfxLayerState();
}

class _LuminaVfxLayerState extends State<LuminaVfxLayer>
    with WidgetsBindingObserver {
  late final _LuminaVfxGame _game = _LuminaVfxGame();
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final policy = MotionPolicy.of(context);
    _game
      ..progress = widget.progress.clamp(0, 1)
      ..anchor = widget.anchor
      ..color = widget.color
      ..count = math.min(32, policy.particleBudget);
    if (!_foreground ||
        !TickerMode.valuesOf(context).enabled ||
        policy.reduced) {
      _game.pauseEngine();
    } else {
      _game.resumeEngine();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant LuminaVfxLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: MotionPolicy.of(context).reduced
            ? const SizedBox.expand()
            : GameWidget(game: _game, autofocus: false),
      ),
    ),
  );
}

class _LuminaVfxGame extends FlameGame {
  double progress = 0;
  Offset anchor = const Offset(0.5, 0.58);
  Color color = const Color(0xFFE8BC57);
  int count = 32;
  final Paint _paint = Paint();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (progress <= 0 || progress >= 1 || count == 0) return;
    final center = Offset(size.x * anchor.dx, size.y * anchor.dy);
    final radius = math.min(size.x, size.y) * 0.32;
    final gathering = progress < 0.52;
    final phase = gathering ? progress / 0.52 : (progress - 0.52) / 0.48;
    final alpha = math.sin(math.pi * phase).clamp(0.0, 1.0);
    _paint
      ..color = color.withValues(alpha: alpha * 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, radius * 0.6),
        width: radius * (1.0 + phase),
        height: radius * 0.32,
      ),
      _paint,
    );
    _paint.style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final angle = i * 2.399963 + progress * 0.7;
      final spread = gathering ? 1 - phase * 0.85 : 0.15 + phase;
      final distance = radius * spread * (0.55 + (i % 7) / 14);
      _paint.color = color.withValues(alpha: alpha * (0.4 + (i % 3) * 0.2));
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        1.4 + (i % 3) * 0.6,
        _paint,
      );
    }
  }
}
