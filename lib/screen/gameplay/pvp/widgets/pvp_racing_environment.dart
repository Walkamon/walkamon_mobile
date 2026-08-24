import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/common/app_icon.dart';
import '../../../../widgets/common/asset_only_icon_button.dart';
import '../pvp_asset_resolver.dart';
import '../pvp_race_contract.dart';
import 'pvp_frame_animation.dart';

const double _mapSourceWidth = 1440;
const double _mapSourceHeight = 2560;
const double _startLineLeadingSourceX = 510;
const List<double> _morningLaneCenters = [1280, 1680];
const List<double> _nightLaneCenters = [1008, 1664];

/// Texture phase for the documented 30-second race:
/// start map (0-5s) -> loop map (5-25s) -> finish map (25-30s).
@visibleForTesting
int pvpTrackPhaseIndex(double raceProgress) {
  return PvpRoutePresentationContract.resolve(raceProgress).phaseIndex;
}

@visibleForTesting
double pvpMapHorizontalAlignmentX(String mapAsset) {
  if (mapAsset.contains('_finish_')) return 1;
  if (mapAsset.contains('_loop_')) return 0;
  return -1;
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
  double bodyCenterOffsetX = 0,
  double crossingAnchorOffsetX = 0,
  double leadingAnchorOffsetX = 0,
  String? mapAsset,
  double? mapAlignmentX,
}) {
  if (mapAsset != null && viewportHeight != null) {
    final projected = PvpTrackCoordinateContract.screenX(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      normalizedProgress: progress / 100,
      runnerWidth: runnerWidth,
      bodyCenterOffsetX: bodyCenterOffsetX,
      crossingAnchorOffsetX: crossingAnchorOffsetX,
      mapAlignmentX: mapAlignmentX ?? pvpMapHorizontalAlignmentX(mapAsset),
    );
    // Keep the complete meaningful silhouette visible at both ends. The
    // production finish map has authored runout space, so no pet needs to
    // leave the viewport merely to clear the stripe.
    final maximum = mapAsset.contains('_finish_')
        ? viewportWidth - leadingAnchorOffsetX - 8
        : viewportWidth - runnerWidth / 2 - 8;
    return projected.clamp(runnerWidth / 2 + 8, maximum);
  }
  final coverScale = viewportHeight == null
      ? viewportWidth / _mapSourceWidth
      : math.max(
          viewportWidth / _mapSourceWidth,
          viewportHeight / _mapSourceHeight,
        );
  final startLineX = _startLineLeadingSourceX * coverScale;
  final minimum = math.max(
    runnerWidth / 2 + 8,
    startLineX - runnerWidth / 2 - 8,
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
    this.showFinishReaction = false,
    this.finishResultCode,
    this.onWinnerCrossed,
    required this.onClose,
    required this.mapAssets,
    this.myAffinityCode = 'sprout',
    this.opponentAffinityCode = 'sprout',
    this.myStageNo = 0,
    this.opponentStageNo = 0,
    this.myActiveEffects = const <String>[],
    this.opponentActiveEffects = const <String>[],
    this.myTransientEffect,
    this.opponentTransientEffect,
    this.transientVfxSequence = 0,
    this.myAnimationState = 'race',
    this.opponentAnimationState = 'race',
    this.animationsPaused = false,
    this.debugShowGeometry = false,
  });

  final bool isMoving;
  final double trackProgress;
  final double myProgress;
  final double opponentProgress;
  final String opponentName;
  final String racePhase;
  final bool isFinished;
  final bool showFinishReaction;
  final String? finishResultCode;
  final VoidCallback? onWinnerCrossed;
  final FutureOr<void> Function() onClose;
  final List<String> mapAssets;
  final String myAffinityCode;
  final String opponentAffinityCode;
  final int myStageNo;
  final int opponentStageNo;
  final List<String> myActiveEffects;
  final List<String> opponentActiveEffects;
  final String? myTransientEffect;
  final String? opponentTransientEffect;
  final int transientVfxSequence;
  final String myAnimationState;
  final String opponentAnimationState;

  /// Used by deterministic visual regression capture. Production callers
  /// leave this false, so race and finish clips always play normally.
  final bool animationsPaused;
  final bool debugShowGeometry;

  @override
  State<PvPRacingEnvironment> createState() => _PvPRacingEnvironmentState();
}

class _PvPRacingEnvironmentState extends State<PvPRacingEnvironment>
    with SingleTickerProviderStateMixin {
  String? _precacheKey;
  late final AnimationController _ambientController;
  bool _reportedWinnerCrossing = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (!widget.animationsPaused) _ambientController.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheRaceAssets();
  }

  @override
  void didUpdateWidget(covariant PvPRacingEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheRaceAssets();
    if (oldWidget.animationsPaused != widget.animationsPaused) {
      if (widget.animationsPaused) {
        _ambientController.stop();
      } else {
        _ambientController.repeat();
      }
    }
    if (oldWidget.finishResultCode != widget.finishResultCode ||
        (widget.myProgress < oldWidget.myProgress &&
            widget.opponentProgress < oldWidget.opponentProgress)) {
      _reportedWinnerCrossing = false;
    }
  }

  void _reportWinnerCrossingAfterBuild(bool winnerCrossed) {
    if (!winnerCrossed || _reportedWinnerCrossing) return;
    _reportedWinnerCrossing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onWinnerCrossed?.call();
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _precacheRaceAssets() {
    final assets = <String>{
      ...widget.mapAssets,
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.myAffinityCode,
        stageNo: widget.myStageNo,
      ),
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.myAffinityCode,
        stageNo: widget.myStageNo,
        state: 'win',
      ),
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.myAffinityCode,
        stageNo: widget.myStageNo,
        state: 'lose',
      ),
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.opponentAffinityCode,
        stageNo: widget.opponentStageNo,
      ),
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.opponentAffinityCode,
        stageNo: widget.opponentStageNo,
        state: 'win',
      ),
      ...PvpAssetResolver.petAnimationFrames(
        affinityCode: widget.opponentAffinityCode,
        stageNo: widget.opponentStageNo,
        state: 'lose',
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
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final maps = _trackMaps;
        final normalizedTrackProgress = widget.trackProgress
            .clamp(0.0, 1.0)
            .toDouble();
        final route = PvpRoutePresentationContract.resolve(
          normalizedTrackProgress,
        );
        final trackPhaseIndex = route.phaseIndex;
        final activeMap = maps[trackPhaseIndex];
        final nextMap = maps[route.nextPhaseIndex];
        final remainingSeconds =
            ((1 - normalizedTrackProgress) * pvpRaceDurationSeconds)
                .ceil()
                .clamp(0, 30);
        final segmentLabel = switch (trackPhaseIndex) {
          0 => l10n.pvpRaceSegmentStart,
          1 => l10n.pvpRaceSegmentTrail,
          _ => l10n.pvpRaceSegmentFinish,
        };
        final myOutcomeState = widget.myAnimationState.trim().toLowerCase();
        final finishResultCode =
            widget.finishResultCode?.trim().toLowerCase() ?? myOutcomeState;
        final outcomeLabel = switch (finishResultCode) {
          'win' => l10n.pvpResultVictoryTitle,
          'lose' => l10n.pvpResultDefeatTitle,
          'draw' => l10n.pvpResultDrawTitle,
          _ => l10n.pvpResultTitle,
        };
        final opponentMetrics = PvpPetVisualMetrics.resolve(
          widget.opponentAffinityCode,
          widget.opponentStageNo,
        );
        final myMetrics = PvpPetVisualMetrics.resolve(
          widget.myAffinityCode,
          widget.myStageNo,
        );
        final opponentPetSize = opponentMetrics.correctedSize(
          (height * 0.15).clamp(88.0, 118.0).toDouble(),
        );
        final myPetSize = myMetrics.correctedSize(
          (height * 0.18).clamp(104.0, 138.0).toDouble(),
        );
        final opponentRunnerWidth = opponentPetSize + 24;
        final myRunnerWidth = myPetSize + 24;
        final opponentTrailingEdgeOffsetX = opponentMetrics.trailingEdgeOffsetX(
          opponentPetSize,
        );
        final opponentLeadingEdgeOffsetX = opponentMetrics.leadingEdgeOffsetX(
          opponentPetSize,
        );
        final opponentBodyCenterOffsetX = opponentMetrics.bodyCenterOffsetX(
          opponentPetSize,
        );
        final myTrailingEdgeOffsetX = myMetrics.trailingEdgeOffsetX(myPetSize);
        final myLeadingEdgeOffsetX = myMetrics.leadingEdgeOffsetX(myPetSize);
        final myBodyCenterOffsetX = myMetrics.bodyCenterOffsetX(myPetSize);
        final opponentRunnerX = pvpRunnerScreenX(
          viewportWidth: width,
          viewportHeight: height,
          progress: widget.opponentProgress,
          runnerWidth: opponentRunnerWidth,
          bodyCenterOffsetX: opponentBodyCenterOffsetX,
          crossingAnchorOffsetX: opponentTrailingEdgeOffsetX,
          leadingAnchorOffsetX: opponentLeadingEdgeOffsetX,
          mapAsset: activeMap,
          mapAlignmentX: route.cameraAlignmentX,
        );
        final myRunnerX = pvpRunnerScreenX(
          viewportWidth: width,
          viewportHeight: height,
          progress: widget.myProgress,
          runnerWidth: myRunnerWidth,
          bodyCenterOffsetX: myBodyCenterOffsetX,
          crossingAnchorOffsetX: myTrailingEdgeOffsetX,
          leadingAnchorOffsetX: myLeadingEdgeOffsetX,
          mapAsset: activeMap,
          mapAlignmentX: route.cameraAlignmentX,
        );
        final finishLineX = PvpTrackCoordinateContract.finishLineScreenX(
          viewportWidth: width,
          viewportHeight: height,
          mapAlignmentX: route.cameraAlignmentX,
        );
        _reportWinnerCrossingAfterBuild(
          trackPhaseIndex == 2 &&
              hasPvpWinnerCrossedFinishLine(
                resultCode: widget.finishResultCode,
                myTrailingEdgeX: myRunnerX + myTrailingEdgeOffsetX,
                opponentTrailingEdgeX:
                    opponentRunnerX + opponentTrailingEdgeOffsetX,
                finishLineX: finishLineX,
              ),
        );

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            RepaintBoundary(
              key: const ValueKey('pvp-continuous-route-background'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    activeMap,
                    key: ValueKey(activeMap),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    alignment: Alignment(route.cameraAlignmentX, 0),
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                  if (route.nextMapOpacity > 0 && nextMap != activeMap)
                    Opacity(
                      opacity: route.nextMapOpacity,
                      child: Image.asset(
                        nextMap,
                        key: ValueKey(nextMap),
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                        alignment: Alignment(route.cameraAlignmentX, 0),
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) => CustomPaint(
                  key: const ValueKey('pvp-ambient-layer'),
                  painter: _PvpAmbientPainter(
                    progress: widget.animationsPaused
                        ? 0.35
                        : _ambientController.value,
                    isNight: activeMap.contains('_night_'),
                    routeProgress: normalizedTrackProgress,
                  ),
                ),
              ),
            ),
            _Runner(
              progress: widget.opponentProgress,
              screenX: opponentRunnerX,
              laneCenterY: pvpLaneCenterY(
                viewportWidth: width,
                viewportHeight: height,
                mapAsset: activeMap,
                laneIndex: 0,
              ),
              label: widget.opponentName,
              labelColor: theme.colorScheme.surface.withValues(alpha: 0.84),
              labelTextColor: theme.colorScheme.onSurface,
              affinityCode: widget.opponentAffinityCode,
              stageNo: widget.opponentStageNo,
              petSize: opponentPetSize,
              baselineCorrection: opponentMetrics.baselineCorrection(
                opponentPetSize,
              ),
              nameOffset: opponentMetrics.nameOffset(opponentPetSize),
              activeEffects: widget.opponentActiveEffects,
              transientEffect: widget.opponentTransientEffect,
              transientVfxSequence: widget.transientVfxSequence,
              isMoving: widget.isMoving,
              animationState: widget.opponentAnimationState,
              animationsPaused: widget.animationsPaused,
            ),
            if (kDebugMode && widget.debugShowGeometry)
              IgnorePointer(
                child: CustomPaint(
                  painter: _PvpDebugGeometryPainter(
                    laneOneY: pvpLaneCenterY(
                      viewportWidth: width,
                      viewportHeight: height,
                      mapAsset: activeMap,
                      laneIndex: 0,
                    ),
                    laneTwoY: pvpLaneCenterY(
                      viewportWidth: width,
                      viewportHeight: height,
                      mapAsset: activeMap,
                      laneIndex: 1,
                    ),
                    cameraAlignmentX: route.cameraAlignmentX,
                    routeProgress: normalizedTrackProgress,
                  ),
                ),
              ),
            _Runner(
              progress: widget.myProgress,
              screenX: myRunnerX,
              laneCenterY: pvpLaneCenterY(
                viewportWidth: width,
                viewportHeight: height,
                mapAsset: activeMap,
                laneIndex: 1,
              ),
              label: l10n.pvpYou,
              labelColor: AppColors.leafLight.withValues(alpha: 0.9),
              labelTextColor: theme.colorScheme.onPrimary,
              affinityCode: widget.myAffinityCode,
              stageNo: widget.myStageNo,
              petSize: myPetSize,
              baselineCorrection: myMetrics.baselineCorrection(myPetSize),
              nameOffset: myMetrics.nameOffset(myPetSize),
              activeEffects: widget.myActiveEffects,
              transientEffect: widget.myTransientEffect,
              transientVfxSequence: widget.transientVfxSequence,
              isMoving: widget.isMoving,
              animationState: widget.myAnimationState,
              animationsPaused: widget.animationsPaused,
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
                      AssetOnlyIconButton(
                        onPressed: widget.onClose,
                        semanticLabel: l10n.pvpCloseRace,
                        icon: Icons.close,
                        buttonSize: 44,
                        assetSize: 38,
                      ),
                      const Spacer(),
                      Semantics(
                        label: l10n.pvpRaceProgress(
                          (normalizedTrackProgress * 100).round(),
                        ),
                        child: Container(
                          key: const ValueKey('pvp-race-status'),
                          constraints: const BoxConstraints(minWidth: 166),
                          padding: const EdgeInsets.fromLTRB(13, 7, 13, 8),
                          decoration: BoxDecoration(
                            color: AppColors.authCard.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.woodDeep.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.woodDeep.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeIn,
                                child: widget.showFinishReaction
                                    ? Row(
                                        key: const ValueKey(
                                          'pvp-finish-reaction',
                                        ),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AppIcon(
                                            switch (finishResultCode) {
                                              'win' =>
                                                Icons.emoji_events_rounded,
                                              'draw' => Icons.handshake_rounded,
                                              _ => Icons.favorite_rounded,
                                            },
                                            size: 18,
                                            color: switch (finishResultCode) {
                                              'win' => AppColors.gold,
                                              'draw' => AppColors.sky,
                                              _ => AppColors.pink,
                                            },
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            outcomeLabel,
                                            key: const ValueKey(
                                              'pvp-finish-reaction-label',
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.woodDeep,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        key: const ValueKey(
                                          'pvp-race-time-row',
                                        ),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.pvpRaceTimeRemaining(
                                              remainingSeconds,
                                            ),
                                            key: const ValueKey(
                                              'pvp-race-time',
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.woodDeep,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var index = 0; index < 3; index++) ...[
                                    AnimatedContainer(
                                      key: ValueKey('pvp-race-phase-$index'),
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: index == trackPhaseIndex ? 14 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: index == trackPhaseIndex
                                            ? AppColors.oliveDeep
                                            : AppColors.woodLight.withValues(
                                                alpha: 0.65,
                                              ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    if (index != 2) const SizedBox(width: 4),
                                  ],
                                  const SizedBox(width: 7),
                                  Text(
                                    segmentLabel,
                                    key: const ValueKey('pvp-race-segment'),
                                    style: const TextStyle(
                                      color: AppColors.inkBrown,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
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
            if (_shouldShowCountdown)
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Container(
                    key: ValueKey('countdown-${widget.racePhase}'),
                    constraints: const BoxConstraints(minWidth: 138),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.authCard.withValues(alpha: .90),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.woodDeep.withValues(alpha: .72),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .26),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Text(
                      switch (widget.racePhase.toLowerCase()) {
                        '3' => l10n.pvpRaceCountdownReady,
                        '2' => l10n.pvpRaceCountdownSet,
                        'go' => l10n.pvpRaceGo,
                        _ => widget.racePhase,
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.woodDeep,
                        letterSpacing: .4,
                      ),
                    ),
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
    required this.baselineCorrection,
    required this.nameOffset,
    required this.activeEffects,
    required this.transientEffect,
    required this.transientVfxSequence,
    required this.isMoving,
    required this.animationState,
    required this.animationsPaused,
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
  final double baselineCorrection;
  final double nameOffset;
  final List<String> activeEffects;
  final String? transientEffect;
  final int transientVfxSequence;
  final bool isMoving;
  final String animationState;
  final bool animationsPaused;

  @override
  Widget build(BuildContext context) {
    final runnerWidth = petSize + 24;
    final runnerHeight = petSize + 50;
    final effects = <String>[...activeEffects];
    if (transientEffect != null) {
      effects.add(transientEffect!);
    }
    final normalizedEffects = effects.map((effect) => effect.toLowerCase());
    final isSlowed = normalizedEffects.any(
      (effect) => effect.contains('slow') || effect.contains('mud'),
    );
    final isShielded = normalizedEffects.any(
      (effect) => effect.contains('shield') || effect.contains('barrier'),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOutCubic,
      left: screenX - runnerWidth / 2,
      top: laneCenterY + petSize * .42 - runnerHeight + baselineCorrection,
      width: runnerWidth,
      height: runnerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Transform.translate(
            offset: Offset(0, nameOffset),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 80),
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.woodDeep.withValues(alpha: 0.16),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: runnerWidth,
            height: petSize + 24,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: baselineCorrection - 2,
                  child: AnimatedContainer(
                    key: const ValueKey('pvp-runner-shadow'),
                    duration: const Duration(milliseconds: 180),
                    width: petSize * (isMoving ? .58 : .52),
                    height: petSize * .115,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: isMoving ? .18 : .14,
                      ),
                      borderRadius: BorderRadius.circular(petSize),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .10),
                          blurRadius: 7,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMoving && progress > .01)
                  Positioned(
                    left: 4,
                    bottom: baselineCorrection + 2,
                    child: _RunnerDust(progress: progress),
                  ),
                for (final effect in effects.where(_isUnderlayEffect))
                  if (PvpAssetResolver.vfxFrames(effect).isNotEmpty)
                    PvpFrameAnimation(
                      key: ValueKey(
                        'vfx-$effect-${effect == transientEffect ? transientVfxSequence : 0}',
                      ),
                      effectCode: effect,
                      width: runnerWidth,
                      height: petSize + 24,
                      playing: !animationsPaused && (isMoving || progress > 0),
                    ),
                if (isSlowed || isShielded)
                  AnimatedSlide(
                    key: const ValueKey('pvp-runner-effect-reaction'),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    offset: isSlowed
                        ? const Offset(0, .035)
                        : const Offset(0, -.025),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      scale: isSlowed ? .94 : 1.035,
                      child: PvpPetAnimation(
                        affinityCode: affinityCode,
                        stageNo: stageNo,
                        state: animationState,
                        width: petSize,
                        height: petSize,
                        playing:
                            !animationsPaused &&
                            (isMoving || animationState != 'race'),
                      ),
                    ),
                  )
                else
                  PvpPetAnimation(
                    affinityCode: affinityCode,
                    stageNo: stageNo,
                    state: animationState,
                    width: petSize,
                    height: petSize,
                    playing:
                        !animationsPaused &&
                        (isMoving || animationState != 'race'),
                  ),
                for (final effect in effects.where(
                  (e) => !_isUnderlayEffect(e),
                ))
                  if (PvpAssetResolver.vfxFrames(effect).isNotEmpty)
                    PvpFrameAnimation(
                      key: ValueKey(
                        'vfx-overlay-$effect-${effect == transientEffect ? transientVfxSequence : 0}',
                      ),
                      effectCode: effect,
                      width: runnerWidth,
                      height: petSize + 24,
                      playing: !animationsPaused && (isMoving || progress > 0),
                    ),
                if (effects.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: effects
                          .take(3)
                          .map((effect) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Image.asset(
                                PvpAssetResolver.statusIcon(effect) ??
                                    PvpAssetResolver.itemIcon(effect) ??
                                    AppAssets.pvpHasteStatus,
                                width: 22,
                                height: 22,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isUnderlayEffect(String effect) {
    final normalized = effect.toLowerCase();
    return normalized.contains('haste') ||
        normalized.contains('speed') ||
        normalized.contains('slow');
  }
}

class _RunnerDust extends StatelessWidget {
  const _RunnerDust({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .35 + (progress * 5 % 1) * .22,
      child: Row(
        children: const [
          _DustDot(size: 7),
          SizedBox(width: 4),
          _DustDot(size: 4),
          SizedBox(width: 3),
          _DustDot(size: 3),
        ],
      ),
    );
  }
}

class _DustDot extends StatelessWidget {
  const _DustDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE9D9AE).withValues(alpha: .75),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PvpAmbientPainter extends CustomPainter {
  const _PvpAmbientPainter({
    required this.progress,
    required this.isNight,
    required this.routeProgress,
  });

  final double progress;
  final bool isNight;
  final double routeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var index = 0; index < 7; index++) {
      final phase = (progress + index * .137 + routeProgress * .11) % 1;
      final x = (index * 0.173 + phase * .22) % 1 * size.width;
      final y = (index * .219 + phase * .34) % 1 * size.height;
      final radius = 1.5 + (index % 3) * .7;
      paint.color = isNight
          ? const Color(0xFFD8F4FF).withValues(alpha: .22 + .12 * phase)
          : const Color(0xFFFFF1B0).withValues(alpha: .18 + .10 * phase);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PvpAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isNight != isNight ||
      oldDelegate.routeProgress != routeProgress;
}

class _PvpDebugGeometryPainter extends CustomPainter {
  const _PvpDebugGeometryPainter({
    required this.laneOneY,
    required this.laneTwoY,
    required this.cameraAlignmentX,
    required this.routeProgress,
  });

  final double laneOneY;
  final double laneTwoY;
  final double cameraAlignmentX;
  final double routeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = const Color(0xCC00E5FF)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, laneOneY),
      Offset(size.width, laneOneY),
      lanePaint,
    );
    canvas.drawLine(
      Offset(0, laneTwoY),
      Offset(size.width, laneTwoY),
      lanePaint,
    );
    final text = TextPainter(
      text: TextSpan(
        text:
            'route ${(routeProgress * 100).toStringAsFixed(1)}%  cam ${cameraAlignmentX.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFF001214),
          backgroundColor: Color(0xCCB2F7FF),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(8, 62));
  }

  @override
  bool shouldRepaint(covariant _PvpDebugGeometryPainter oldDelegate) =>
      oldDelegate.laneOneY != laneOneY ||
      oldDelegate.laneTwoY != laneTwoY ||
      oldDelegate.cameraAlignmentX != cameraAlignmentX ||
      oldDelegate.routeProgress != routeProgress;
}
