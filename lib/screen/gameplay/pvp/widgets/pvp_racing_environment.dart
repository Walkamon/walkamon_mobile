import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../widgets/common/app_icon.dart';
import '../pvp_asset_resolver.dart';
import 'pvp_frame_animation.dart';
import 'pvp_two_slot_hud.dart';

const double _startPhaseEnd = 5 / 30;
const double _finishPhaseStart = 25 / 30;

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
double pvpLaneBaseline(double viewportHeight, int laneIndex) {
  return viewportHeight * (laneIndex == 0 ? 0.58 : 0.73);
}

@visibleForTesting
double pvpRunnerScreenX({
  required double viewportWidth,
  required double progress,
  required double runnerWidth,
}) {
  final minimum = math.max(viewportWidth * 0.10, runnerWidth / 2 + 8);
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
    this.leftSlot = const PvpHudSlot(itemCode: 'haste'),
    this.rightSlot = const PvpHudSlot(itemCode: 'shield'),
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
  final PvpHudSlot leftSlot;
  final PvpHudSlot rightSlot;

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final maps = _trackMaps;
        final activeMap = maps[pvpTrackPhaseIndex(widget.trackProgress)];
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
                children: [
                  ...previousChildren,
                  ?currentChild,
                ],
              ),
              child: Image.asset(
                activeMap,
                key: ValueKey(activeMap),
                width: width,
                height: height,
                fit: BoxFit.cover,
                alignment: Alignment.center,
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
                progress: widget.opponentProgress,
                runnerWidth: opponentPetSize + 24,
              ),
              baselineY: pvpLaneBaseline(height, 0),
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
                progress: widget.myProgress,
                runnerWidth: myPetSize + 24,
              ),
              baselineY: pvpLaneBaseline(height, 1),
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
                      IconButton.filledTonal(
                        onPressed: widget.onClose,
                        icon: const AppIcon(Icons.close),
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
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Stack(
                            children: [
                              AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 100),
                                widthFactor: (widget.myProgress / 100)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                alignment: Alignment.centerLeft,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              AnimatedFractionallySizedBox(
                                duration: const Duration(milliseconds: 100),
                                widthFactor: (widget.opponentProgress / 100)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                alignment: Alignment.centerLeft,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + bottomInset,
              child: PvpTwoSlotHud(
                left: widget.leftSlot,
                right: widget.rightSlot,
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
    required this.baselineY,
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
  final double baselineY;
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
      top: baselineY - runnerHeight,
      width: runnerWidth,
      height: runnerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
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
