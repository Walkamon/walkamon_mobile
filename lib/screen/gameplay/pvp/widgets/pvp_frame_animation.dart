import 'package:flutter/material.dart';

import '../pvp_asset_resolver.dart';

class PvpPetAnimationContract {
  const PvpPetAnimationContract._();

  static int fpsFor(String state) => switch (state.trim().toLowerCase()) {
    'race' => 15,
    'lose' => 4,
    _ => 8,
  };

  static int selectedFrameCount(String state, int availableFrames) {
    if (state.trim().toLowerCase() == 'lose' && availableFrames > 4) return 4;
    return availableFrames;
  }

  static bool loops(String state) => state.trim().toLowerCase() == 'race';

  /// Clip-level normalization measured from the median meaningful alpha
  /// height of every authored frame. Race is the visual-size reference.
  ///
  /// This deliberately stays constant for a whole clip: per-frame scaling
  /// would erase the authored squash/stretch and introduce visible pumping.
  static double visualScaleFor({
    required String affinityCode,
    required int stageNo,
    required String state,
  }) {
    final normalizedState = state.trim().toLowerCase();
    if (normalizedState == 'race') return 1;
    final affinity = affinityCode.trim().toLowerCase();
    return switch ((affinity, stageNo.clamp(1, 2), normalizedState)) {
      (_, _, String value) when value != 'win' && value != 'lose' => 1,
      ('warm_sun', 1, 'win') => 1.02,
      ('warm_sun', 1, 'lose') => 1.04,
      ('warm_sun', 2, 'win') => .96,
      ('warm_sun', 2, 'lose') => 1.02,
      ('moonlight', 1, 'win') => 1.02,
      ('moonlight', 1, 'lose') => 1.09,
      ('moonlight', 2, 'win') => .97,
      ('moonlight', 2, 'lose') => 1.11,
      ('dawn', 1, 'win') => .87,
      ('dawn', 1, 'lose') => .89,
      ('dawn', 2, 'win') => .82,
      ('dawn', 2, 'lose') => .92,
      (_, _, 'win') => .83,
      (_, _, 'lose') => .85,
      _ => 1,
    };
  }
}

/// Plays an 8-frame PvP VFX strip from `assets/Mobile/PVP/vfx/...`.
class PvpFrameAnimation extends StatefulWidget {
  const PvpFrameAnimation({
    super.key,
    required this.effectCode,
    this.width = 96,
    this.height = 96,
    this.playing = true,
  });

  final String effectCode;
  final double width;
  final double height;
  final bool playing;

  @override
  State<PvpFrameAnimation> createState() => _PvpFrameAnimationState();
}

class _PvpFrameAnimationState extends State<PvpFrameAnimation>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  late List<String> _frames;
  late bool _loops;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(covariant PvpFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effectCode != widget.effectCode) {
      _controller?.dispose();
      _configure();
    } else if (oldWidget.playing != widget.playing) {
      _syncPlayback();
    }
  }

  void _configure() {
    _frames = PvpAssetResolver.vfxFrames(widget.effectCode);
    _loops = PvpAssetResolver.vfxLoops(widget.effectCode);
    final fps = PvpAssetResolver.vfxFps(widget.effectCode);
    if (_frames.isEmpty) {
      _controller = null;
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_frames.length * 1000 / fps).round()),
    );
    _syncPlayback();
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null) return;
    if (!widget.playing) {
      controller.stop();
      return;
    }
    if (_loops) {
      controller.repeat();
    } else {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_frames.isEmpty || controller == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final index = (controller.value * _frames.length).floor().clamp(
          0,
          _frames.length - 1,
        );
        return Image.asset(
          _frames[index],
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        );
      },
    );
  }
}

/// Plays the dedicated PvP pet sequence (`race`, `win`, or `lose`) using the
/// exact case-sensitive paths documented by the PvP asset contract. Outcome
/// clips play once and hold their most readable reaction pose.
class PvpPetAnimation extends StatefulWidget {
  const PvpPetAnimation({
    super.key,
    required this.affinityCode,
    required this.stageNo,
    this.state = 'race',
    this.width = 96,
    this.height = 96,
    this.playing = true,
  });

  final String affinityCode;
  final int stageNo;
  final String state;
  final double width;
  final double height;
  final bool playing;

  @override
  State<PvpPetAnimation> createState() => _PvpPetAnimationState();
}

class _PvpPetAnimationState extends State<PvpPetAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<String> _frames;
  late bool _loops;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(covariant PvpPetAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.affinityCode != widget.affinityCode ||
        oldWidget.stageNo != widget.stageNo ||
        oldWidget.state != widget.state) {
      _controller.dispose();
      _configure();
    } else if (oldWidget.playing != widget.playing) {
      _syncPlayback();
    }
  }

  void _configure() {
    final state = widget.state.trim().toLowerCase();
    final resolvedFrames = PvpAssetResolver.petAnimationFrames(
      affinityCode: widget.affinityCode,
      stageNo: widget.stageNo,
      state: state,
    );
    // The authored lose strip returns to a neutral running pose in F05-F08.
    // During a post-race reaction that made the loser appear recovered before
    // the result card arrived. Stop at the lowest defeated pose (F04) and hold
    // it; win plays through to its happy final pose and holds there.
    final selectedCount = PvpPetAnimationContract.selectedFrameCount(
      state,
      resolvedFrames.length,
    );
    _frames = selectedCount < resolvedFrames.length
        ? resolvedFrames.take(selectedCount).toList(growable: false)
        : resolvedFrames;
    _loops = PvpPetAnimationContract.loops(state);
    final fps = PvpPetAnimationContract.fpsFor(state);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_frames.length * 1000 / fps).round()),
    );
    _syncPlayback();
  }

  void _syncPlayback() {
    if (!widget.playing) {
      _controller.stop();
      return;
    }
    if (_loops) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clipScale = PvpPetAnimationContract.visualScaleFor(
      affinityCode: widget.affinityCode,
      stageNo: widget.stageNo,
      state: widget.state,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final index = (_controller.value * _frames.length).floor().clamp(
          0,
          _frames.length - 1,
        );
        return AnimatedScale(
          scale: clipScale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            _frames[index],
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}
