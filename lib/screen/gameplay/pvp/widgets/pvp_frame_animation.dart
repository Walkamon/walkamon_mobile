import 'package:flutter/material.dart';

import '../pvp_asset_resolver.dart';

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
    with SingleTickerProviderStateMixin {
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
/// exact case-sensitive paths documented by the PvP asset contract.
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
    with SingleTickerProviderStateMixin {
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
    _frames = PvpAssetResolver.petAnimationFrames(
      affinityCode: widget.affinityCode,
      stageNo: widget.stageNo,
      state: state,
    );
    _loops = state == 'race';
    final fps = _loops ? 12 : 10;
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final index = (_controller.value * _frames.length).floor().clamp(
          0,
          _frames.length - 1,
        );
        return Image.asset(
          _frames[index],
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        );
      },
    );
  }
}
