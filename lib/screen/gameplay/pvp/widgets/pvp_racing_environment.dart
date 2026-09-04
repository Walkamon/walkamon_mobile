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
        // The loop artwork is the continuous visual base. Start and finish
        // markings are composited independently, so neither landmark vanishes
        // through a full-texture swap while the runners are moving.
        final baseMap = maps[1];
        final finishRevealProgress = trackPhaseIndex == 2
            ? 1.0
            : route.nextPhaseIndex == 2
            ? route.nextMapOpacity
            : 0.0;
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
                    baseMap,
                    key: ValueKey(baseMap),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    alignment: Alignment(route.cameraAlignmentX, 0),
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                  if (route.startLineOpacity > 0)
                    Opacity(
                      opacity: route.startLineOpacity,
                      child: Transform.translate(
                        key: const ValueKey('pvp-outgoing-start-line'),
                        offset: Offset(
                          width * route.startLineOffsetFraction,
                          0,
                        ),
                        child: ClipPath(
                          clipper: _PvpStartStripeClipper(
                            alignmentX: route.cameraAlignmentX,
                            isNight: maps[0].contains('_night_'),
                          ),
                          child: Image.asset(
                            maps[0],
                            key: ValueKey(maps[0]),
                            width: width,
                            height: height,
                            fit: BoxFit.cover,
                            alignment: Alignment(route.cameraAlignmentX, 0),
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  if (finishRevealProgress > 0)
                    Opacity(
                      opacity: finishRevealProgress,
                      child: Transform.translate(
                        key: const ValueKey('pvp-incoming-finish-line'),
                        offset: Offset(
                          width * route.incomingMapOffsetFraction,
                          0,
                        ),
                        child: ClipPath(
                          clipper: _PvpFinishStripeClipper(
                            alignmentX: route.cameraAlignmentX,
                            isNight: maps[2].contains('_night_'),
                          ),
                          child: Image.asset(
                            maps[2],
                            key: ValueKey(maps[2]),
                            width: width,
                            height: height,
                            fit: BoxFit.cover,
                            alignment: Alignment(route.cameraAlignmentX, 0),
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                          ),
                        ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.racePhase.toLowerCase() != 'go') ...[
                          Text(
                            l10n.pvpRaceCountdownReady,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.inkBrown,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          widget.racePhase.toLowerCase() == 'go'
                              ? l10n.pvpRaceGo
                              : widget.racePhase,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.woodDeep,
                            letterSpacing: .4,
                          ),
                        ),
                      ],
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
    // Realtime responses can expose the same effect in the active snapshot
    // and as the just-triggered transient event. Render one canonical layer;
    // stacking both was making bubbles/mist opaque and visually oversized.
    final effects = <String>[];
    final effectFamilies = <String>{};
    void addEffect(String? effect) {
      final value = effect?.trim();
      if (value == null || value.isEmpty) return;
      if (effectFamilies.add(_pvpEffectFamily(value))) effects.add(value);
    }

    addEffect(transientEffect);
    for (final effect in activeEffects) {
      addEffect(effect);
    }
    final transientFamily = transientEffect == null
        ? null
        : _pvpEffectFamily(transientEffect!);
    final normalizedEffects = effects.map(_pvpEffectFamily);
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
              clipBehavior: Clip.none,
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
                    _RunnerVfxLayer(
                      key: ValueKey(
                        'vfx-${_pvpEffectFamily(effect)}-${_pvpEffectFamily(effect) == transientFamily ? transientVfxSequence : 0}',
                      ),
                      effectCode: effect,
                      petSize: petSize,
                      runnerWidth: runnerWidth,
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
                    _RunnerVfxLayer(
                      key: ValueKey(
                        'vfx-overlay-${_pvpEffectFamily(effect)}-${_pvpEffectFamily(effect) == transientFamily ? transientVfxSequence : 0}',
                      ),
                      effectCode: effect,
                      petSize: petSize,
                      runnerWidth: runnerWidth,
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
    final family = _pvpEffectFamily(effect);
    return family == 'haste' || family == 'slow';
  }
}

String _pvpEffectFamily(String effect) {
  final normalized = effect.trim().toLowerCase();
  if (normalized.contains('slow') || normalized.contains('mud')) return 'slow';
  if (normalized.contains('shield') || normalized.contains('barrier')) {
    return 'shield';
  }
  if (normalized.contains('cleanse') || normalized.contains('purif')) {
    return 'cleanse';
  }
  if (normalized.contains('haste') || normalized.contains('speed')) {
    return 'haste';
  }
  return normalized;
}

class _RunnerVfxLayer extends StatelessWidget {
  const _RunnerVfxLayer({
    super.key,
    required this.effectCode,
    required this.petSize,
    required this.runnerWidth,
    required this.playing,
  });

  final String effectCode;
  final double petSize;
  final double runnerWidth;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final family = _pvpEffectFamily(effectCode);
    final (width, height, bottom, horizontalOffset, opacity) = switch (family) {
      // A speed trail belongs behind the runner and should read as motion,
      // not as a ribbon laid across the pet's face.
      'haste' => (
        runnerWidth * 1.10,
        petSize * .58,
        petSize * .06,
        -runnerWidth * .24,
        .62,
      ),
      // Keep mist around the paws; the authored ring has a large footprint.
      'slow' => (petSize * .82, petSize * .55, -2.0, 0.0, .58),
      // Cleanse is a short burst, scaled below the silhouette height so the
      // face remains readable throughout the action.
      'cleanse' => (petSize * .82, petSize * .82, petSize * .04, 0.0, .68),
      // Shield remains visible but translucent instead of replacing the pet.
      'shield' => (petSize * .96, petSize * .96, 0.0, 0.0, .56),
      _ => (petSize * .82, petSize * .82, 0.0, 0.0, .62),
    };

    return Positioned(
      left: (runnerWidth - width) / 2 + horizontalOffset,
      bottom: bottom,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: PvpFrameAnimation(
            effectCode: effectCode,
            width: width,
            height: height,
            playing: playing,
          ),
        ),
      ),
    );
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

class _PvpStartStripeClipper extends CustomClipper<Path> {
  const _PvpStartStripeClipper({
    required this.alignmentX,
    required this.isNight,
  });

  final double alignmentX;
  final bool isNight;

  @override
  Path getClip(Size size) {
    final geometry = PvpCoverGeometry.resolve(
      viewportWidth: size.width,
      viewportHeight: size.height,
      sourceWidth: _mapSourceWidth,
      sourceHeight: _mapSourceHeight,
      alignmentX: alignmentX,
    );
    final sourcePolygons = isNight
        ? const [
            [
              Offset(507, 725),
              Offset(576, 725),
              Offset(541, 1294),
              Offset(470, 1294),
            ],
            [
              Offset(507, 1405),
              Offset(576, 1405),
              Offset(541, 1960),
              Offset(470, 1960),
            ],
          ]
        : const [
            [
              Offset(507, 1115),
              Offset(579, 1115),
              Offset(542, 1460),
              Offset(468, 1460),
            ],
            [
              Offset(507, 1508),
              Offset(579, 1508),
              Offset(542, 1898),
              Offset(468, 1898),
            ],
          ];
    final path = Path();
    Offset project(Offset source) => Offset(
      geometry.left + source.dx * geometry.scale,
      geometry.top + source.dy * geometry.scale,
    );
    for (final polygon in sourcePolygons) {
      final first = project(polygon.first);
      path.moveTo(first.dx, first.dy);
      for (final source in polygon.skip(1)) {
        final point = project(source);
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _PvpStartStripeClipper oldClipper) =>
      oldClipper.alignmentX != alignmentX || oldClipper.isNight != isNight;
}

class _PvpFinishStripeClipper extends CustomClipper<Path> {
  const _PvpFinishStripeClipper({
    required this.alignmentX,
    required this.isNight,
  });

  final double alignmentX;
  final bool isNight;

  @override
  Path getClip(Size size) {
    final geometry = PvpCoverGeometry.resolve(
      viewportWidth: size.width,
      viewportHeight: size.height,
      sourceWidth: _mapSourceWidth,
      sourceHeight: _mapSourceHeight,
      alignmentX: alignmentX,
    );
    final sourcePolygons = isNight
        ? const [
            [
              Offset(808, 730),
              Offset(892, 730),
              Offset(892, 1290),
              Offset(808, 1290),
            ],
            [
              Offset(808, 1410),
              Offset(892, 1410),
              Offset(892, 1975),
              Offset(808, 1975),
            ],
          ]
        : const [
            [
              Offset(806, 1115),
              Offset(888, 1115),
              Offset(918, 1455),
              Offset(832, 1455),
            ],
            [
              Offset(837, 1515),
              Offset(920, 1515),
              Offset(960, 1895),
              Offset(876, 1895),
            ],
          ];
    final path = Path();
    Offset project(Offset source) => Offset(
      geometry.left + source.dx * geometry.scale,
      geometry.top + source.dy * geometry.scale,
    );
    for (final polygon in sourcePolygons) {
      path.moveTo(project(polygon.first).dx, project(polygon.first).dy);
      for (final source in polygon.skip(1)) {
        final point = project(source);
        path.lineTo(point.dx, point.dy);
      }
      path.close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _PvpFinishStripeClipper oldClipper) =>
      oldClipper.alignmentX != alignmentX || oldClipper.isNight != isNight;
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
