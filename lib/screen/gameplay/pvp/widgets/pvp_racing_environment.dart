import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../widgets/common/app_icon.dart';
import '../pvp_asset_resolver.dart';
import 'pvp_frame_animation.dart';

const double _startPhaseEnd = 5 / 30;
const double _finishPhaseStart = 25 / 30;
const double _mapSourceWidth = 1440;
const double _mapSourceHeight = 2560;
const double _startLineLeadingSourceX = 92;
const double _petForwardVisibleFactor = 0.40;
const List<double> _morningLaneCenters = [1280, 1680];
const List<double> _nightLaneCenters = [1008, 1664];

/// Texture phase for the documented 30-second race:
/// start map (0-5s) -> loop map (5-25s) -> finish map (25-30s).
@visibleForTesting
int pvpTrackPhaseIndex(double raceProgress) {
  final progress = raceProgress.clamp(0.0, 1.0);
  if (progress < _startPhaseEnd) return 0;
  if (progress < _finishPhaseStart) return 1;
  return 2;
}

@visibleForTesting
double pvpLaneCenterY({
  required double viewportWidth,
  required double viewportHeight,
  required String mapAsset,
  required int laneIndex,
}) {
  assert(laneIndex == 0 || laneIndex == 1);
  final sourceCenters = mapAsset.contains('_night_')
      ? _nightLaneCenters
      : _morningLaneCenters;
  final coverScale = math.max(
    viewportWidth / _mapSourceWidth,
    viewportHeight / _mapSourceHeight,
  );
  final renderedHeight = _mapSourceHeight * coverScale;
  final centeredCoverTop = (viewportHeight - renderedHeight) / 2;
  return centeredCoverTop + sourceCenters[laneIndex] * coverScale;
}

@visibleForTesting
double pvpRunnerScreenX({
  required double viewportWidth,
  double? viewportHeight,
  required double progress,
  required double runnerWidth,
}) {
  final coverScale = viewportHeight == null
      ? viewportWidth / _mapSourceWidth
      : math.max(
          viewportWidth / _mapSourceWidth,
          viewportHeight / _mapSourceHeight,
        );
  final startLineX = _startLineLeadingSourceX * coverScale;
  final petWidth = math.max(0.0, runnerWidth - 24);
  final minimum = math.max(
    0.0,
    startLineX - petWidth * _petForwardVisibleFactor,
  );
  final maximum = math.min(
    viewportWidth * 0.90,
    viewportWidth - runnerWidth / 2 - 8,
  );
  final normalizedProgress = (progress.clamp(0, 100) / 100).toDouble();
  return lerpDouble(minimum, math.max(minimum, maximum), normalizedProgress)!;
}

class PvPRacingEnvironment extends StatefulWidget {
  const PvPRacingEnvironment({
    super.key,
    required this.isMoving,
    required this.trackProgress,
    required this.myProgress,
    required this.opponentProgress,
    required this.opponentName,
    required this.racePhase,
    required this.isFinished,
    required this.onClose,
    required this.mapAssets,
    this.myAffinityCode = 'sprout',
    this.opponentAffinityCode = 'sprout',
    this.myStageNo = 0,
    this.opponentStageNo = 0,
    this.myActiveEffects = const <String>[],
    this.opponentActiveEffects = const <String>[],
  });

  final bool isMoving;
  final double trackProgress;
  final double myProgress;
  final double opponentProgress;
  final String opponentName;
  final String racePhase;
  final bool isFinished;
  final FutureOr<void> Function() onClose;
  final List<String> mapAssets;
  final String myAffinityCode;
  final String opponentAffinityCode;
  final int myStageNo;
  final int opponentStageNo;
  final List<String> myActiveEffects;
  final List<String> opponentActiveEffects;

  @override
  State<PvPRacingEnvironment> createState() => _PvPRacingEnvironmentState();
}

class _PvPRacingEnvironmentState extends State<PvPRacingEnvironment> {
  String? _precacheKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheRaceAssets();
  }

  @override
  void didUpdateWidget(covariant PvPRacingEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheRaceAssets();
  }

  void _precacheRaceAssets() {
    final assets = <String>{
      ...widget.mapAssets,
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.myAffinityCode,
        stageNo: widget.myStageNo,
      ),
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.opponentAffinityCode,
        stageNo: widget.opponentStageNo,
      ),
    };
    final key = assets.join('|');
    if (_precacheKey == key) return;
    _precacheKey = key;
    for (final asset in assets) {
      unawaited(precacheImage(AssetImage(asset), context));
    }
  }

  bool get _shouldShowCountdown {
    if (widget.isFinished) return false;
    final phase = widget.racePhase.toLowerCase();
    return phase != 'ready' && phase != 'running' && phase != 'finished';
  }

  List<String> get _trackMaps {
    if (widget.mapAssets.length >= 3) return widget.mapAssets.take(3).toList();
    if (widget.mapAssets.isNotEmpty) {
      return List<String>.filled(3, widget.mapAssets.first);
    }
    return const [
      AppAssets.pvpMapMorningStart,
      AppAssets.pvpMapMorningLoop,
      AppAssets.pvpMapMorningFinish,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final maps = _trackMaps;
        final normalizedTrackProgress = widget.trackProgress
            .clamp(0.0, 1.0)
            .toDouble();
        final activeMap = maps[pvpTrackPhaseIndex(normalizedTrackProgress)];
        const opponentPetSize = 72.0;
        const myPetSize = 84.0;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [...previousChildren, ?currentChild],
              ),
              child: Image.asset(
                activeMap,
                key: ValueKey(activeMap),
                width: width,
                height: height,
                fit: BoxFit.cover,
                alignment: activeMap == maps.first
                    ? Alignment.centerLeft
                    : Alignment.center,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            _Runner(
              progress: widget.opponentProgress,
              screenX: pvpRunnerScreenX(
                viewportWidth: width,
                viewportHeight: height,
                progress: widget.opponentProgress,
                runnerWidth: opponentPetSize + 24,
              ),
              laneCenterY: pvpLaneCenterY(
                viewportWidth: width,
                viewportHeight: height,
                mapAsset: activeMap,
                laneIndex: 0,
              ),
              label: widget.opponentName,
              labelColor: theme.colorScheme.surface,
              labelTextColor: theme.colorScheme.onSurface,
              affinityCode: widget.opponentAffinityCode,
              stageNo: widget.opponentStageNo,
              petSize: opponentPetSize,
              activeEffects: widget.opponentActiveEffects,
              isMoving: widget.isMoving,
            ),
            _Runner(
              progress: widget.myProgress,
              screenX: pvpRunnerScreenX(
                viewportWidth: width,
                viewportHeight: height,
                progress: widget.myProgress,
                runnerWidth: myPetSize + 24,
              ),
              laneCenterY: pvpLaneCenterY(
                viewportWidth: width,
                viewportHeight: height,
                mapAsset: activeMap,
                laneIndex: 1,
              ),
              label: 'Bạn',
              labelColor: theme.colorScheme.primary,
              labelTextColor: theme.colorScheme.onPrimary,
              affinityCode: widget.myAffinityCode,
              stageNo: widget.myStageNo,
              petSize: myPetSize,
              activeEffects: widget.myActiveEffects,
              isMoving: widget.isMoving,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const AppIcon(Icons.close, size: 28),
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SPRINT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label: 'Race progress',
                          value: '${(normalizedTrackProgress * 100).round()}%',
                          child: Container(
                            key: const ValueKey('pvp-race-progress-track'),
                            height: 12,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                AnimatedFractionallySizedBox(
                                  key: const ValueKey('pvp-race-progress-fill'),
                                  duration: const Duration(milliseconds: 100),
                                  widthFactor: normalizedTrackProgress,
                                  heightFactor: 1,
                                  alignment: Alignment.centerLeft,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.tertiary,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: const Alignment(-2 / 3, 0),
                                  child: Container(
                                    width: 1,
                                    height: 12,
                                    color: Colors.white38,
                                  ),
                                ),
                                Align(
                                  alignment: const Alignment(2 / 3, 0),
                                  child: Container(
                                    width: 1,
                                    height: 12,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const AppIcon(
                        Icons.sports_score_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_shouldShowCountdown)
              Center(
                child: Text(
                  widget.racePhase.toUpperCase(),
                  style: TextStyle(
                    fontSize: widget.racePhase == 'go' ? 110 : 120,
                    fontWeight: FontWeight.bold,
                    color: widget.racePhase == 'go'
                        ? Colors.amber
                        : Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Runner extends StatelessWidget {
  const _Runner({
    required this.progress,
    required this.screenX,
    required this.laneCenterY,
    required this.label,
    required this.labelColor,
    required this.labelTextColor,
    required this.affinityCode,
    required this.stageNo,
    required this.petSize,
    required this.activeEffects,
    required this.isMoving,
  });

  final double progress;
  final double screenX;
  final double laneCenterY;
  final String label;
  final Color labelColor;
  final Color labelTextColor;
  final String affinityCode;
  final int stageNo;
  final double petSize;
  final List<String> activeEffects;
  final bool isMoving;

  @override
  Widget build(BuildContext context) {
    final effect = activeEffects.isNotEmpty ? activeEffects.first : null;
    final runnerWidth = petSize + 24;
    final runnerHeight = petSize + 50;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      left: screenX - runnerWidth / 2,
      top: laneCenterY - runnerHeight + petSize / 2,
      width: runnerWidth,
      height: runnerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            alignment: screenX < runnerWidth / 2
                ? Alignment.centerRight
                : Alignment.center,
            child: Container(
              constraints: BoxConstraints(maxWidth: runnerWidth),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: labelColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: runnerWidth,
            height: petSize + 24,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                if (effect != null)
                  PvpFrameAnimation(
                    effectCode: effect,
                    width: runnerWidth,
                    height: petSize + 24,
                    playing: isMoving || progress > 0,
                  ),
                PvpPetAnimation(
                  affinityCode: affinityCode,
                  stageNo: stageNo,
                  width: petSize,
                  height: petSize,
                  playing: isMoving,
                ),
                if (effect != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Image.asset(
                      PvpAssetResolver.statusIcon(effect) ??
                          PvpAssetResolver.itemIcon(effect) ??
                          AppAssets.pvpHasteStatus,
                      width: 22,
                      height: 22,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
