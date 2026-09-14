import 'package:flutter/material.dart';
import '../../core/motion/motion_tokens.dart';

/// Decorates an existing accessible button, without adding a second gesture
/// recognizer or delaying its callback. Keyboard/semantics remain on the child.
class WalkamonPressable extends StatefulWidget {
  const WalkamonPressable({
    super.key,
    required this.child,
    this.enabled = true,
  });
  final Widget child;
  final bool enabled;

  @override
  State<WalkamonPressable> createState() => _WalkamonPressableState();
}

class _WalkamonPressableState extends State<WalkamonPressable> {
  final Set<int> _pointers = {};

  void _release(int pointer) {
    if (_pointers.remove(pointer)) setState(() {});
  }

  @override
  void didUpdateWidget(covariant WalkamonPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _pointers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pressed =
        widget.enabled &&
        _pointers.isNotEmpty &&
        !MotionPolicy.of(context).reduced;
    return Listener(
      onPointerDown: widget.enabled
          ? (event) => setState(() => _pointers.add(event.pointer))
          : null,
      onPointerUp: (event) => _release(event.pointer),
      onPointerCancel: (event) => _release(event.pointer),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,
        duration: pressed ? MotionTokens.press : MotionTokens.release,
        curve: MotionTokens.enterCurve,
        child: widget.child,
      ),
    );
  }
}
