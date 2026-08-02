import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_colors.dart';

import 'app_audio_service.dart';

/// Adds the shared tab sound to every enabled tappable control in the app.
class AppTapSoundRegion extends StatefulWidget {
  const AppTapSoundRegion({super.key, required this.child, this.onTabSound});

  final Widget child;
  final VoidCallback? onTabSound;

  @override
  State<AppTapSoundRegion> createState() => _AppTapSoundRegionState();
}

class _AppTapSoundRegionState extends State<AppTapSoundRegion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  Offset? _pressPosition;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool _isTappable(PointerEvent event) {
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(
      result,
      event.position,
      event.viewId,
    );

    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderSemanticsGestureHandler && target.onTap != null) {
        return true;
      }
      if (target is SemanticsAnnotationsMixin &&
          target.properties.onTap != null) {
        return true;
      }
    }
    return false;
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isTappable(event)) return;

    scheduleMicrotask(() {
      final audio = AppAudioService.instance;
      if (audio.consumeTabSoundSuppression()) return;
      final callback = widget.onTabSound;
      if (callback != null) {
        callback();
      } else {
        unawaited(audio.playTab());
      }
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    AppAudioService.instance.unlockBackgroundFromUserGesture();
    if (!_isTappable(event)) return;

    setState(() => _pressPosition = event.localPosition);
    _pressController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_pressPosition case final position?)
            Positioned(
              left: position.dx - 24,
              top: position.dy - 24,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pressController,
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      _pressController.value,
                    );
                    return Opacity(
                      opacity: (1 - progress).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.45 + (progress * 0.8),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.ivory.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.22),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
