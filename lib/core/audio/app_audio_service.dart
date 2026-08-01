import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../constants/app_audio_assets.dart';

enum _AppSoundEffect { feed, levelUp, reward, tab, useItem }

class AppAudioService with WidgetsBindingObserver {
  AppAudioService._();

  static final AppAudioService instance = AppAudioService._();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final Map<_AppSoundEffect, AudioPlayer> _effectPlayers = {};

  bool _initialized = false;
  bool _backgroundUnlocked = !kIsWeb;
  bool _backgroundEnabled = true;
  bool _effectsEnabled = true;
  bool _appActive = true;
  bool _backgroundPlaying = false;
  String? _currentBackgroundAsset;
  String _desiredBackgroundAsset = AppAudioAssets.homeMusic;
  Future<void>? _backgroundSync;
  bool _backgroundSyncQueued = false;
  DateTime? _suppressTabSoundUntil;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
      if (kIsWeb) {
        await _prepareWebBackground();
      }
    } catch (error) {
      debugPrint('Không thể khởi tạo hệ thống âm thanh: $error');
    }
    if (!kIsWeb) {
      _requestBackgroundSync();
    }
  }

  Future<void> _prepareWebBackground() async {
    final asset = _desiredBackgroundAsset;
    await _backgroundPlayer.setVolume(0.35);
    await _backgroundPlayer.setSource(AssetSource(asset));
    _currentBackgroundAsset = asset;
    debugPrint('[BGM] Da nap nhac nen Web, dang cho thao tac nguoi dung.');
  }

  void unlockBackgroundFromUserGesture() {
    if (!_initialized || _backgroundUnlocked) return;
    _backgroundUnlocked = true;
    debugPrint('[BGM] Da mo khoa am thanh tu thao tac nguoi dung.');
    _requestBackgroundSync();
  }

  void setEffectsEnabled(bool enabled) {
    if (_effectsEnabled == enabled) return;
    _effectsEnabled = enabled;
    if (!enabled) {
      for (final player in _effectPlayers.values) {
        unawaited(player.stop());
      }
    }
  }

  void setBackgroundEnabled(bool enabled) {
    if (_backgroundEnabled == enabled) {
      // Also acts as an ensure-playing call after hot reload/rebuild.
      _requestBackgroundSync();
      return;
    }
    _backgroundEnabled = enabled;
    debugPrint('[BGM] ${enabled ? 'Bat' : 'Tat'} nhac nen.');
    _requestBackgroundSync();
  }

  void setCurrentRoute(String routeName) {
    if (routeName.isEmpty) return;
    if (routeName.startsWith('/pvp')) return;
    // Route changes keep the default app music. PvP switches music only after
    // a match is actually assigned (countdown/running), not in its lobby.
    playHomeMusic();
  }

  void playHomeMusic() => _selectBackground(AppAudioAssets.homeMusic);

  void playBattleMusic() => _selectBackground(AppAudioAssets.battleMusic);

  void _selectBackground(String assetPath) {
    if (_desiredBackgroundAsset == assetPath &&
        _currentBackgroundAsset == assetPath &&
        _backgroundPlaying) {
      return;
    }
    _desiredBackgroundAsset = assetPath;
    _requestBackgroundSync();
  }

  Future<void> playFeed() =>
      _playEffect(_AppSoundEffect.feed, AppAudioAssets.homeFeed);

  Future<void> playLevelUp() =>
      _playEffect(_AppSoundEffect.levelUp, AppAudioAssets.homeLevelUp);

  Future<void> playReward() =>
      _playEffect(_AppSoundEffect.reward, AppAudioAssets.reward);

  Future<void> playTab() =>
      _playEffect(_AppSoundEffect.tab, AppAudioAssets.tab, volume: 0.65);

  void suppressNextTabSound() {
    _suppressTabSoundUntil = DateTime.now().add(
      const Duration(milliseconds: 150),
    );
  }

  bool consumeTabSoundSuppression() {
    final suppressUntil = _suppressTabSoundUntil;
    _suppressTabSoundUntil = null;
    return suppressUntil != null && DateTime.now().isBefore(suppressUntil);
  }

  Future<void> playUseItem() =>
      _playEffect(_AppSoundEffect.useItem, AppAudioAssets.useItem);

  Future<void> _playEffect(
    _AppSoundEffect effect,
    String assetPath, {
    double volume = 0.9,
  }) async {
    if (!_effectsEnabled || !_appActive) return;

    final player = _effectPlayers.putIfAbsent(effect, AudioPlayer.new);
    try {
      await player.stop();
      await player.play(AssetSource(assetPath), volume: volume);
    } catch (error) {
      debugPrint('Không thể phát hiệu ứng âm thanh $assetPath: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _requestBackgroundSync();
  }

  void _requestBackgroundSync() {
    if (!_initialized) return;
    if (_backgroundSync != null) {
      _backgroundSyncQueued = true;
      return;
    }

    final sync = _syncBackground();
    _backgroundSync = sync;
    unawaited(
      sync.whenComplete(() {
        _backgroundSync = null;
        if (_backgroundSyncQueued) {
          _backgroundSyncQueued = false;
          _requestBackgroundSync();
        }
      }),
    );
  }

  Future<void> _syncBackground() async {
    try {
      if (!_backgroundEnabled || !_appActive || !_backgroundUnlocked) {
        if (_backgroundPlaying) {
          await _backgroundPlayer.pause();
          _backgroundPlaying = false;
        }
        return;
      }

      final desiredAsset = _desiredBackgroundAsset;
      if (_currentBackgroundAsset != desiredAsset) {
        await _backgroundPlayer.play(
          AssetSource(desiredAsset),
          volume: desiredAsset == AppAudioAssets.battleMusic ? 0.42 : 0.35,
        );
        _currentBackgroundAsset = desiredAsset;
        _backgroundPlaying = true;
        debugPrint('[BGM] Dang phat: $desiredAsset');
      } else if (!_backgroundPlaying) {
        await _backgroundPlayer.resume();
        _backgroundPlaying = true;
        debugPrint('[BGM] Da tiep tuc phat: $desiredAsset');
      }
    } catch (error) {
      debugPrint('Không thể đồng bộ nhạc nền: $error');
      _backgroundPlaying = false;
    }
  }
}
