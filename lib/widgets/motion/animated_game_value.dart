import 'package:flutter/material.dart';
import '../../core/motion/motion_tokens.dart';

/// Starts at the first server value, then retargets from the currently drawn
/// value. No callbacks mutate state when the interpolation completes.
class AnimatedGameValue extends StatefulWidget {
  const AnimatedGameValue({
    super.key,
    required this.value,
    required this.builder,
    this.duration = MotionTokens.counter,
  });
  final double value;
  final Widget Function(BuildContext, double) builder;
  final Duration duration;

  @override
  State<AnimatedGameValue> createState() => _AnimatedGameValueState();
}

class _AnimatedGameValueState extends State<AnimatedGameValue>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late double _from;
  late double _target;
  bool _active = true;
  bool _reduced = false;
  double get _value =>
      _from +
      (_target - _from) * MotionTokens.settleCurve.transform(_controller.value);

  @override
  void initState() {
    super.initState();
    _from = _target = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
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
    if (_reduced || !_active) _controller.value = 1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active =
        state == AppLifecycleState.resumed &&
        TickerMode.valuesOf(context).enabled;
    // Resume shows the reconciled value, never a backlog of cosmetic updates.
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedGameValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _target) return;
    _from = _value;
    _target = widget.value;
    _controller.duration = widget.duration;
    if (_reduced || !_active) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(context, _value),
  );
}

class AnimatedGameCounter extends StatelessWidget {
  const AnimatedGameCounter({
    super.key,
    required this.value,
    this.format,
    this.style,
    this.suffix = '',
  });
  final int value;
  final String Function(int)? format;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${format?.call(value) ?? value}$suffix',
    child: ExcludeSemantics(
      child: AnimatedGameValue(
        value: value.toDouble(),
        builder: (context, current) => Text(
          '${format?.call(current.round()) ?? current.round()}$suffix',
          style: (style ?? const TextStyle()).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ),
  );
}

class AnimatedGameProgress extends StatelessWidget {
  const AnimatedGameProgress({
    super.key,
    required this.value,
    required this.builder,
  });
  final double value;
  final Widget Function(BuildContext, double, Widget?) builder;

  @override
  Widget build(BuildContext context) => AnimatedGameValue(
    value: value.clamp(0.0, 1.0),
    builder: (context, value) => builder(context, value, null),
  );
}
