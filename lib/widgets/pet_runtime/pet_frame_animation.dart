import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

List<String> petEvolvedExcitedAnimationFrames({
  required String affinityCode,
  required int stageNo,
}) {
  final stage = stageNo.clamp(1, 2);
  final normalizedAffinity = affinityCode.trim().toLowerCase();
  final String? root = switch (normalizedAffinity) {
    'moonlight' => 'assets/Mobile/TInh Linh Ánh Trăng/stage$stage/excited',
    'dawn' => 'assets/Mobile/Tinh Linh Bình Minh/stage$stage/excited',
    'warm_sun' when stage == 1 => 'assets/Mobile/TinhLinhNangAm/Stage1/excited',
    'warm_sun' => 'assets/Mobile/TinhLinhNangAm/stage2/excited',
    _ => null,
  };
  if (root == null) return const [];

  final frameCount = stage == 1 ? 8 : 5;
  return List<String>.generate(
    frameCount,
    (index) => '$root/excited_F${(index + 1).toString().padLeft(2, '0')}.png',
    growable: false,
  );
}

/// Resolves the legacy frame-by-frame pet artwork bundled with the app.
///
/// The feed-success action intentionally uses the happier-looking `happy`
/// artwork instead of the legacy `feed_eat` artwork. Every frame uses a fixed
/// 512x512 canvas, so switching images does not move the pet around.
List<String> petFeedSuccessAnimationFrames({
  required String affinityCode,
  required int stageNo,
}) {
  final normalizedAffinity = affinityCode.trim().toLowerCase();
  final clampedStage = stageNo.clamp(1, 2);

  final (String root, int frameCount) = switch (normalizedAffinity) {
    'dawn' => (
      'assets/Mobile/Tinh Linh Bình Minh/stage$clampedStage/happy',
      clampedStage == 1 ? 8 : 5,
    ),
    'moonlight' => (
      'assets/Mobile/TInh Linh Ánh Trăng/stage$clampedStage/happy',
      clampedStage == 1 ? 8 : 5,
    ),
    'warm_sun' when clampedStage == 1 => (
      'assets/Mobile/TinhLinhNangAm/Stage1/happy',
      8,
    ),
    'warm_sun' => ('assets/Mobile/TinhLinhNangAm/stage2/happy', 5),
    _ => ('assets/Mobile/Mầm Non/happy', 5),
  };

  return List<String>.generate(
    frameCount,
    (index) => '$root/happy_F${(index + 1).toString().padLeft(2, '0')}.png',
    growable: false,
  );
}

/// Plays a list of equally-sized PNG frames in a loop.
class PetFrameAnimation extends StatefulWidget {
  const PetFrameAnimation({
    super.key,
    required this.frames,
    this.fps = 10,
    this.fit = BoxFit.contain,
  });

  final List<String> frames;
  final int fps;
  final BoxFit fit;

  @override
  State<PetFrameAnimation> createState() => _PetFrameAnimationState();
}

class _PetFrameAnimationState extends State<PetFrameAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _start(restart: true);
  }

  @override
  void didUpdateWidget(covariant PetFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.frames, widget.frames) ||
        oldWidget.fps != widget.fps) {
      _start(restart: true);
    }
  }

  void _start({required bool restart}) {
    final frameCount = widget.frames.length;
    final safeFps = widget.fps.clamp(1, 60);
    _controller.duration = Duration(
      milliseconds: (frameCount * 1000 / safeFps).round().clamp(1, 60000),
    );

    if (frameCount > 1) {
      _controller.repeat(min: 0, max: 1, period: _controller.duration);
    } else {
      _controller.stop();
      if (restart) _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final index = (_controller.value * widget.frames.length).floor().clamp(
          0,
          widget.frames.length - 1,
        );
        return Image.asset(
          widget.frames[index],
          fit: widget.fit,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        );
      },
    );
  }
}
