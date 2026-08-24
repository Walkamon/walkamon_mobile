import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'pet_runtime_models.dart';

@immutable
class PetRuntimeDebugInfo {
  const PetRuntimeDebugInfo({
    required this.formKey,
    required this.state,
    required this.phase,
    required this.clipId,
    required this.assetKey,
    required this.frameIndex,
    required this.frameCount,
    required this.frameDuration,
    required this.fps,
    required this.groundAnchor,
  });

  const PetRuntimeDebugInfo.loading()
    : formKey = 'loading',
      state = PetSemanticState.idle,
      phase = 'load',
      clipId = '-',
      assetKey = '-',
      frameIndex = 0,
      frameCount = 0,
      frameDuration = 0,
      fps = 0,
      groundAnchor = 1;

  final String formKey;
  final PetSemanticState state;
  final String phase;
  final String clipId;
  final String assetKey;
  final int frameIndex;
  final int frameCount;
  final double frameDuration;
  final double fps;
  final double groundAnchor;
}

class PetProductionGame extends FlameGame {
  PetProductionGame({
    required PetRuntimeInput input,
    PetRuntimeManifestLoader? manifestLoader,
  }) : _input = input,
       _manifestLoader = manifestLoader ?? PetRuntimeManifestLoader() {
    images = Images(prefix: '');
  }

  final PetRuntimeManifestLoader _manifestLoader;
  PetRuntimeInput _input;
  PetRuntimeManifest? _manifest;
  PetSpritePlayer? _player;
  late final PetFootprintShadow _shadow;
  bool _resourcesDisposed = false;
  double _debugElapsed = 0;
  double _fpsElapsed = 0;
  int _fpsFrames = 0;
  double _fps = 0;

  final ValueNotifier<PetRuntimeDebugInfo> debugInfo = ValueNotifier(
    const PetRuntimeDebugInfo.loading(),
  );

  PetRuntimeDebugInfo get currentDebugInfo => _buildDebugInfo();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final manifest = await _manifestLoader.load();
    _manifest = manifest;
    final form = manifest.formOrSprout(_input.formKey);

    _shadow = PetFootprintShadow(motionMode: form.motionMode, priority: 0);
    final player = PetSpritePlayer(
      game: this,
      manifest: manifest,
      form: form,
      priority: 1,
    );
    _player = player;
    await addAll([_shadow, player]);
    _layout(form);
    // Do not keep Flame's loading lifecycle open for the duration of an enter
    // or one-shot action clip. Components must be mounted and renderable while
    // those sequences advance, including when the API's first state is sleep,
    // hungry, feed, or hello rather than idle.
    unawaited(player.initialize(_input));
    unawaited(player.preloadHomeActions());
  }

  void updateInput(PetRuntimeInput input) {
    if (_input == input) return;
    _input = input;
    _player?.acceptInput(input);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final manifest = _manifest;
    if (manifest != null) {
      _layout(manifest.formOrSprout(_input.formKey));
    }
  }

  void onPlayerFormChanged(PetRuntimeFormDefinition form) {
    _shadow.motionMode = form.motionMode;
    _layout(form);
  }

  void _layout(PetRuntimeFormDefinition form) {
    final player = _player;
    if (player == null || size.x <= 0 || size.y <= 0) return;
    final side = math.min(size.x, size.y);
    final canvasSide = side * form.homeCanvasScale;
    final groundY = size.y - math.max(3.0, side * 0.025);
    final baseline = _manifest?.baselineNormalized ?? 1.0;
    player
      ..size.setValues(canvasSide, canvasSide)
      ..basePosition.setValues(
        size.x / 2,
        groundY + canvasSide * (1 - baseline),
      )
      ..position.setFrom(player.basePosition);
    _shadow.layout(
      centerX: size.x / 2,
      groundY: groundY,
      petVisibleWidth: canvasSide * 0.56,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _fpsElapsed += dt;
    _fpsFrames++;
    if (_fpsElapsed >= 0.5) {
      _fps = _fpsFrames / _fpsElapsed;
      _fpsElapsed = 0;
      _fpsFrames = 0;
    }
    _debugElapsed += dt;
    if (_debugElapsed >= 0.25) {
      _debugElapsed = 0;
      final player = _player;
      if (player != null) {
        debugInfo.value = _buildDebugInfo();
      }
    }
  }

  PetRuntimeDebugInfo _buildDebugInfo() {
    final player = _player;
    if (player == null) return const PetRuntimeDebugInfo.loading();
    final clip = player.currentClip;
    final frameIndex = player.animationTicker?.currentIndex ?? 0;
    final duration = clip == null || frameIndex >= clip.durations.length
        ? 0.0
        : clip.durations[frameIndex];
    return PetRuntimeDebugInfo(
      formKey: player.form.key,
      state: player.displayedState,
      phase: player.phase,
      clipId: clip?.id ?? '-',
      assetKey: clip?.sheet ?? '-',
      frameIndex: frameIndex,
      frameCount: clip?.frameCount ?? 0,
      frameDuration: duration,
      fps: _fps,
      groundAnchor: _manifest?.baselineNormalized ?? 1,
    );
  }

  void setPlaybackSpeed(double speed) {
    _player?.playbackSpeed = speed.clamp(0.1, 2.0);
  }

  void setPaused(bool paused) {
    final player = _player;
    if (player != null) {
      player.setPaused(paused);
    }
  }

  void stepFrame(int delta) => _player?.stepFrame(delta);

  @visibleForTesting
  bool freezeCurrentClipFrameForCapture(int frameIndex) =>
      _player?.freezeCurrentClipFrameForCapture(frameIndex) ?? false;

  void disposeResources() {
    if (_resourcesDisposed) return;
    _resourcesDisposed = true;
    images.clearCache();
    debugInfo.dispose();
  }
}

class PetSpritePlayer extends SpriteAnimationComponent {
  PetSpritePlayer({
    required this.game,
    required this.manifest,
    required PetRuntimeFormDefinition form,
    super.priority,
  }) : _form = form,
       super(
         anchor: Anchor.bottomCenter,
         size: Vector2.zero(),
         autoResize: false,
       );

  final PetProductionGame game;
  final PetRuntimeManifest manifest;
  final Vector2 basePosition = Vector2.zero();
  final Map<String, SpriteAnimation> _animationCache = {};
  PetRuntimeFormDefinition _form;
  PetSemanticState _authoritativeState = PetSemanticState.idle;
  PetSemanticState _displayedState = PetSemanticState.idle;
  PetRuntimeInput? _lastInput;
  PetRuntimeClip? _currentClip;
  Completer<bool>? _pendingCompletion;
  int _sequenceToken = 0;
  bool _actionActive = false;
  bool _paused = false;
  double _hoverClock = 0;
  double playbackSpeed = 1;
  String phase = 'load';

  PetRuntimeFormDefinition get form => _form;
  PetSemanticState get displayedState => _displayedState;
  PetRuntimeClip? get currentClip => _currentClip;

  Future<void> initialize(PetRuntimeInput input) async {
    _lastInput = input;
    _authoritativeState = input.state.isAction
        ? PetSemanticState.idle
        : input.state;
    if (input.state.isAction) {
      await _playAction(input.state);
    } else {
      await _transitionTo(input.state, force: true);
    }
  }

  Future<void> preloadHomeActions() async {
    await _preloadClips([
      ..._form.stateOrIdle(PetSemanticState.feedEat).action,
      ..._form.stateOrIdle(PetSemanticState.tapHello).action,
    ]);
  }

  void acceptInput(PetRuntimeInput input) {
    final previous = _lastInput;
    _lastInput = input;
    final resolvedForm = manifest.formOrSprout(input.formKey);
    if (resolvedForm.key != _form.key) {
      _sequenceToken++;
      _cancelPending();
      _actionActive = false;
      _form = resolvedForm;
      _animationCache.clear();
      game.onPlayerFormChanged(resolvedForm);
      _authoritativeState = input.state.isAction
          ? PetSemanticState.idle
          : input.state;
      if (input.state.isAction) {
        unawaited(_playAction(input.state));
      } else {
        unawaited(_transitionTo(input.state, force: true));
      }
      unawaited(preloadHomeActions());
      return;
    }

    if (input.state.isAction) {
      final shouldReplay =
          previous?.state != input.state ||
          previous?.actionSerial != input.actionSerial;
      if (shouldReplay && !_actionActive) {
        unawaited(_playAction(input.state));
      }
      return;
    }

    _authoritativeState = input.state;
    if (!_actionActive && input.state != _displayedState) {
      unawaited(_transitionTo(input.state));
    }
  }

  Future<void> _transitionTo(
    PetSemanticState target, {
    bool force = false,
  }) async {
    if (!force && target == _displayedState && phase == 'loop') return;
    final token = ++_sequenceToken;
    _cancelPending();
    final previousDefinition = _form.stateOrIdle(_displayedState);
    final targetDefinition = _form.stateOrIdle(target);
    final preload = <PetRuntimeClip>[
      if (!force && previousDefinition.exit != null) previousDefinition.exit!,
      if (targetDefinition.enter != null) targetDefinition.enter!,
      if (targetDefinition.loop != null) targetDefinition.loop!,
    ];
    if (targetDefinition.loop == null) {
      final neutralLoop = _form.stateOrIdle(PetSemanticState.idle).loop;
      if (neutralLoop != null) preload.add(neutralLoop);
    }
    await _preloadClips(preload);
    if (token != _sequenceToken) return;

    if (!force && previousDefinition.exit != null) {
      if (!await _playOnce(previousDefinition.exit!, token, 'exit')) return;
    }
    if (targetDefinition.enter != null) {
      if (!await _playOnce(targetDefinition.enter!, token, 'enter')) return;
    }
    if (token != _sequenceToken) return;
    _displayedState = target;
    final loop =
        targetDefinition.loop ?? _form.stateOrIdle(PetSemanticState.idle).loop;
    if (loop == null) {
      debugPrint(
        '[PetRuntime] missing loop form=${_form.key} state=${target.wireName}; '
        'neutral idle unavailable',
      );
      return;
    }
    await _setClip(loop, token, 'loop');
  }

  Future<void> _playAction(PetSemanticState action) async {
    final definition = _form.stateOrIdle(action);
    if (definition.action.isEmpty) {
      debugPrint(
        '[PetRuntime] missing action form=${_form.key} '
        'state=${action.wireName}; falling back to neutral idle',
      );
      await _transitionTo(PetSemanticState.idle, force: true);
      return;
    }
    final token = ++_sequenceToken;
    _cancelPending();
    await _preloadClips(definition.action);
    if (token != _sequenceToken) return;
    _actionActive = true;
    _displayedState = action;
    for (var index = 0; index < definition.action.length; index++) {
      if (!await _playOnce(definition.action[index], token, 'action:$index')) {
        return;
      }
    }
    if (token != _sequenceToken) return;
    _actionActive = false;
    await _transitionTo(_authoritativeState, force: true);
  }

  Future<void> _preloadClips(Iterable<PetRuntimeClip> clips) async {
    await Future.wait(clips.map(_loadAnimation));
  }

  Future<bool> _playOnce(
    PetRuntimeClip clip,
    int token,
    String nextPhase,
  ) async {
    if (!await _setClip(clip, token, nextPhase)) return false;
    final completion = Completer<bool>();
    _cancelPending();
    _pendingCompletion = completion;
    final ticker = animationTicker;
    if (ticker == null) return false;
    ticker.onComplete = () {
      if (!completion.isCompleted) completion.complete(token == _sequenceToken);
    };
    return completion.future;
  }

  Future<bool> _setClip(
    PetRuntimeClip clip,
    int token,
    String nextPhase,
  ) async {
    final nextAnimation = await _loadAnimation(clip);
    if (token != _sequenceToken) return false;
    _cancelPending();
    _currentClip = clip;
    phase = nextPhase;
    animation = nextAnimation;
    // Reassigning the same cached SpriteAnimation does not guarantee a fresh
    // ticker. An interrupted transition can otherwise resume on its completed
    // final frame and wait forever for a second onComplete callback.
    animationTicker?.reset();
    // Asset loading is asynchronous. Respect a pause requested while the next
    // clip was loading instead of silently restarting playback on completion.
    playing = !_paused;
    return true;
  }

  Future<SpriteAnimation> _loadAnimation(PetRuntimeClip clip) async {
    final cacheKey = '${_form.key}:${clip.id}';
    final cached = _animationCache[cacheKey];
    if (cached != null) return cached;
    final image = await game.images.load(clip.sheet);
    final frameSize = manifest.runtimeSize.toDouble();
    final frames = List<SpriteAnimationFrame>.generate(clip.frameCount, (
      index,
    ) {
      final column = index % clip.columns;
      final row = index ~/ clip.columns;
      final sprite = Sprite(
        image,
        srcPosition: Vector2(column * frameSize, row * frameSize),
        srcSize: Vector2.all(frameSize),
      );
      return SpriteAnimationFrame(sprite, clip.durations[index]);
    }, growable: false);
    final result = SpriteAnimation(frames, loop: clip.loop);
    _animationCache[cacheKey] = result;
    return result;
  }

  void _cancelPending() {
    final pending = _pendingCompletion;
    _pendingCompletion = null;
    if (pending != null && !pending.isCompleted) pending.complete(false);
  }

  void stepFrame(int delta) {
    _paused = true;
    playing = false;
    final ticker = animationTicker;
    final count = _currentClip?.frameCount ?? 0;
    if (ticker == null || count == 0) return;
    ticker.currentIndex = (ticker.currentIndex + delta) % count;
    if (ticker.currentIndex < 0) ticker.currentIndex += count;
    ticker.clock = 0;
  }

  bool freezeCurrentClipFrameForCapture(int frameIndex) {
    final currentAnimation = animation;
    if (currentAnimation == null || currentAnimation.frames.isEmpty) {
      return false;
    }
    _paused = true;
    playing = false;
    snapAmbientMotionToNeutral();
    final index = frameIndex.clamp(0, currentAnimation.frames.length - 1);
    final source = currentAnimation.frames[index];
    animation = SpriteAnimation([
      SpriteAnimationFrame(source.sprite, source.stepTime),
    ], loop: true);
    animationTicker?.reset();
    playing = false;
    return true;
  }

  void snapAmbientMotionToNeutral() {
    _hoverClock = 0;
    position.setFrom(basePosition);
  }

  void setPaused(bool paused) {
    _paused = paused;
    playing = !paused;
    if (paused) snapAmbientMotionToNeutral();
  }

  @override
  void update(double dt) {
    final scaledDt = dt * playbackSpeed;
    super.update(scaledDt);
    if (_paused) {
      if (position.y != basePosition.y) position.setFrom(basePosition);
      return;
    }
    if (_form.motionMode == PetMotionMode.hover) {
      _hoverClock += scaledDt;
      position.y = basePosition.y + math.sin(_hoverClock * math.pi * 0.7) * 1.6;
    } else if (position.y != basePosition.y) {
      position.setFrom(basePosition);
    }
  }

  @override
  void onRemove() {
    _cancelPending();
    super.onRemove();
  }
}

class PetFootprintShadow extends PositionComponent {
  PetFootprintShadow({required PetMotionMode motionMode, super.priority})
    : _motionMode = motionMode;

  final Paint _paint = Paint()
    ..color = const Color(0x2E1C2442)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  Rect _oval = Rect.zero;
  PetMotionMode _motionMode;

  set motionMode(PetMotionMode value) {
    _motionMode = value;
    _updatePaint();
  }

  void layout({
    required double centerX,
    required double groundY,
    required double petVisibleWidth,
  }) {
    final width =
        petVisibleWidth * (_motionMode == PetMotionMode.hover ? 0.55 : 0.72);
    final height = width * (_motionMode == PetMotionMode.hover ? 0.12 : 0.18);
    _oval = Rect.fromCenter(
      center: Offset(centerX, groundY),
      width: width,
      height: height,
    );
    _updatePaint();
  }

  void _updatePaint() {
    _paint.color = _motionMode == PetMotionMode.hover
        ? const Color(0x184A71B8)
        : const Color(0x32161A2D);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(_oval, _paint);
  }
}
