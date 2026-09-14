import 'package:flutter/material.dart';
import '../../core/motion/motion_tokens.dart';

@immutable
class RaceFrame {
  const RaceFrame(this.track, this.mine, this.opponent);
  final double track;
  final double mine;
  final double opponent;

  RaceFrame between(RaceFrame target, double t) => RaceFrame(
    track + (target.track - track) * t,
    mine + (target.mine - mine) * t,
    opponent + (target.opponent - opponent) * t,
  );
  bool sameAs(RaceFrame other) =>
      track == other.track && mine == other.mine && opponent == other.opponent;
}

/// Interpolates a coherent camera + two-runner snapshot on the display clock.
/// Linear here represents physical movement, not a page transition. Never
/// extrapolates past the most recent provider target or notifies that provider.
class AnimatedRaceFrame extends StatefulWidget {
  const AnimatedRaceFrame({
    super.key,
    required this.target,
    required this.builder,
    this.snap = false,
  });
  final RaceFrame target;
  final bool snap;
  final Widget Function(BuildContext, RaceFrame) builder;
  @override
  State<AnimatedRaceFrame> createState() => _AnimatedRaceFrameState();
}

class _AnimatedRaceFrameState extends State<AnimatedRaceFrame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  late RaceFrame _from;
  late RaceFrame _to;
  bool _active = true;
  bool _reduced = false;
  RaceFrame get _current => _from.between(_to, _clock.value);

  @override
  void initState() {
    super.initState();
    _from = _to = widget.target;
    _clock = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 50),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionPolicy.of(context).reduced;
    _active =
        TickerMode.valuesOf(context).enabled &&
        (WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed);
    if (!_active || _reduced) _clock.value = 1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active =
        state == AppLifecycleState.resumed &&
        TickerMode.valuesOf(context).enabled;
    _clock.value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedRaceFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.target.sameAs(_to)) {
      if (widget.snap) _clock.value = 1;
      return;
    }
    _from = _current;
    _to = widget.target;
    if (widget.snap || !_active || _reduced) {
      _clock.value = 1;
    } else {
      _clock.forward(from: 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => widget.builder(context, _current),
    ),
  );
}
