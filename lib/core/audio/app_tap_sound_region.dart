import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'app_audio_service.dart';

/// Adds the shared tab sound to every enabled tappable control in the app.
class AppTapSoundRegion extends StatelessWidget {
  const AppTapSoundRegion({super.key, required this.child, this.onTabSound});

  final Widget child;
  final VoidCallback? onTabSound;

  bool _isTappable(PointerUpEvent event) {
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
      final callback = onTabSound;
      if (callback != null) {
        callback();
      } else {
        unawaited(audio.playTab());
      }
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    AppAudioService.instance.unlockBackgroundFromUserGesture();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      child: child,
    );
  }
}
