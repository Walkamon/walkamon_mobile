import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pet_production_game.dart';
import 'pet_runtime_models.dart';

class PetRendererHost extends StatefulWidget {
  const PetRendererHost({
    super.key,
    required this.input,
    this.showDebugOverlay = false,
    this.onGameCreated,
  });

  final PetRuntimeInput input;
  final bool showDebugOverlay;
  final ValueChanged<PetProductionGame>? onGameCreated;

  @override
  State<PetRendererHost> createState() => _PetRendererHostState();
}

class _PetRendererHostState extends State<PetRendererHost>
    with WidgetsBindingObserver {
  late final PetProductionGame _game;
  bool _foreground = true;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _game = PetProductionGame(input: widget.input);
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    widget.onGameCreated?.call(_game);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _syncPlayback();
  }

  void _syncPlayback() {
    if (_foreground && _visible) {
      _game.resumeEngine();
    } else {
      _game.pauseEngine();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant PetRendererHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input) {
      _game.updateInput(widget.input);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.pauseEngine();
    _game.disposeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: GameWidget<PetProductionGame>(
                game: _game,
                autofocus: false,
                behavior: HitTestBehavior.translucent,
                loadingBuilder: (context) => const SizedBox.expand(),
                errorBuilder: (context, error) {
                  debugPrint('[PetRuntime] GameWidget load failed: $error');
                  return Center(
                    child: Icon(
                      Icons.spa_outlined,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.72),
                    ),
                  );
                },
              ),
            ),
            if (widget.showDebugOverlay && kDebugMode)
              Positioned(
                left: 4,
                right: 4,
                top: 4,
                child: IgnorePointer(
                  child: ValueListenableBuilder<PetRuntimeDebugInfo>(
                    valueListenable: _game.debugInfo,
                    builder: (context, info, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.66),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          '${info.formKey} · ${info.state.wireName} · ${info.phase}\n'
                          '${info.clipId} · F${info.frameIndex + 1}/${info.frameCount} · '
                          '${(info.frameDuration * 1000).round()}ms\n'
                          '${info.assetKey.split('/').last} · '
                          '${info.fps.toStringAsFixed(1)} FPS · '
                          'anchor ${info.groundAnchor.toStringAsFixed(3)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            height: 1.15,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
