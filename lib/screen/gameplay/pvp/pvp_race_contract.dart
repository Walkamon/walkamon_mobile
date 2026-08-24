import '../../../data/models/pvp_models.dart';

const double pvpRaceDurationSeconds = 30;
const double pvpStartPhaseEnd = 5 / pvpRaceDurationSeconds;
const double pvpFinishPhaseStart = 25 / pvpRaceDurationSeconds;

class PvpRoutePresentation {
  const PvpRoutePresentation({
    required this.phaseIndex,
    required this.nextPhaseIndex,
    required this.phaseProgress,
    required this.nextMapOpacity,
    required this.cameraAlignmentX,
  });

  final int phaseIndex;
  final int nextPhaseIndex;
  final double phaseProgress;
  final double nextMapOpacity;
  final double cameraAlignmentX;
}

/// Single source of truth for the 5s / 20s / 5s presentation route.
///
/// The final 18% of each segment is a deterministic overlap. Both outgoing
/// and incoming maps use the same camera alignment, so a crossfade cannot
/// introduce a horizontal camera snap.
class PvpRoutePresentationContract {
  const PvpRoutePresentationContract._();

  static const double transitionFraction = .18;
  static const List<double> _phaseStarts = [
    0,
    pvpStartPhaseEnd,
    pvpFinishPhaseStart,
  ];
  static const List<double> _phaseEnds = [
    pvpStartPhaseEnd,
    pvpFinishPhaseStart,
    1,
  ];
  static const List<double> _panStarts = [-1, -.35, .40];
  static const List<double> _panEnds = [-.35, .40, 1];

  static PvpRoutePresentation resolve(double rawProgress) {
    final progress = rawProgress.clamp(0.0, 1.0).toDouble();
    final phase = progress < pvpStartPhaseEnd
        ? 0
        : progress < pvpFinishPhaseStart
        ? 1
        : 2;
    final start = _phaseStarts[phase];
    final end = _phaseEnds[phase];
    final local = end <= start
        ? 1.0
        : ((progress - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    final pan = _lerp(_panStarts[phase], _panEnds[phase], _smooth(local));
    final transitionStart = 1 - transitionFraction;
    final fade = phase == 2
        ? 0.0
        : _smooth(
            ((local - transitionStart) / transitionFraction)
                .clamp(0.0, 1.0)
                .toDouble(),
          );
    return PvpRoutePresentation(
      phaseIndex: phase,
      nextPhaseIndex: phase == 2 ? 2 : phase + 1,
      phaseProgress: local,
      nextMapOpacity: fade,
      cameraAlignmentX: pan,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _smooth(double t) => t * t * (3 - 2 * t);
}

class PvpCoverGeometry {
  const PvpCoverGeometry({
    required this.scale,
    required this.renderedWidth,
    required this.renderedHeight,
    required this.left,
    required this.top,
  });

  final double scale;
  final double renderedWidth;
  final double renderedHeight;
  final double left;
  final double top;

  static PvpCoverGeometry resolve({
    required double viewportWidth,
    required double viewportHeight,
    required double sourceWidth,
    required double sourceHeight,
    required double alignmentX,
  }) {
    final scale = viewportWidth / sourceWidth > viewportHeight / sourceHeight
        ? viewportWidth / sourceWidth
        : viewportHeight / sourceHeight;
    final renderedWidth = sourceWidth * scale;
    final renderedHeight = sourceHeight * scale;
    return PvpCoverGeometry(
      scale: scale,
      renderedWidth: renderedWidth,
      renderedHeight: renderedHeight,
      left:
          (viewportWidth - renderedWidth) *
          ((alignmentX.clamp(-1.0, 1.0) + 1) / 2),
      top: (viewportHeight - renderedHeight) / 2,
    );
  }
}

class PvpPetVisualMetrics {
  const PvpPetVisualMetrics({
    required this.scaleCorrection,
    required this.alphaCenterXNormalized,
    required this.alphaLeftNormalized,
    required this.alphaRightNormalized,
    required this.alphaTopNormalized,
    required this.alphaBottomNormalized,
  });

  final double scaleCorrection;
  final double alphaCenterXNormalized;
  final double alphaLeftNormalized;
  final double alphaRightNormalized;
  final double alphaTopNormalized;
  final double alphaBottomNormalized;

  static PvpPetVisualMetrics resolve(String affinityCode, int stageNo) {
    final affinity = affinityCode.trim().toLowerCase();
    return switch ((affinity, stageNo.clamp(1, 2))) {
      ('warm_sun', 1) => const PvpPetVisualMetrics(
        scaleCorrection: 1,
        alphaCenterXNormalized: .5420,
        alphaLeftNormalized: 43 / 512,
        alphaRightNormalized: 459 / 512,
        alphaTopNormalized: 86 / 512,
        alphaBottomNormalized: 445 / 512,
      ),
      ('warm_sun', 2) => const PvpPetVisualMetrics(
        scaleCorrection: .92,
        alphaCenterXNormalized: .5449,
        alphaLeftNormalized: 35 / 512,
        alphaRightNormalized: 457 / 512,
        alphaTopNormalized: 60 / 512,
        alphaBottomNormalized: 452 / 512,
      ),
      ('moonlight', 1) => const PvpPetVisualMetrics(
        scaleCorrection: .92,
        alphaCenterXNormalized: .5273,
        alphaLeftNormalized: 32 / 512,
        alphaRightNormalized: 452 / 512,
        alphaTopNormalized: 80 / 512,
        alphaBottomNormalized: 471 / 512,
      ),
      ('moonlight', 2) => const PvpPetVisualMetrics(
        scaleCorrection: 1.03,
        alphaCenterXNormalized: .5381,
        alphaLeftNormalized: 32 / 512,
        alphaRightNormalized: 468 / 512,
        alphaTopNormalized: 108 / 512,
        alphaBottomNormalized: 458 / 512,
      ),
      ('dawn', 1) => const PvpPetVisualMetrics(
        scaleCorrection: 1.04,
        alphaCenterXNormalized: .5625,
        alphaLeftNormalized: 32 / 512,
        alphaRightNormalized: 443 / 512,
        alphaTopNormalized: 123 / 512,
        alphaBottomNormalized: 468 / 512,
      ),
      ('dawn', 2) => const PvpPetVisualMetrics(
        scaleCorrection: 1.08,
        alphaCenterXNormalized: .5342,
        alphaLeftNormalized: 33 / 512,
        alphaRightNormalized: 469 / 512,
        alphaTopNormalized: 124 / 512,
        alphaBottomNormalized: 457 / 512,
      ),
      _ => const PvpPetVisualMetrics(
        scaleCorrection: 1.10,
        alphaCenterXNormalized: .6113,
        alphaLeftNormalized: 87 / 512,
        alphaRightNormalized: 441 / 512,
        alphaTopNormalized: 140 / 512,
        alphaBottomNormalized: 468 / 512,
      ),
    };
  }

  double correctedSize(double requested) =>
      (requested * scaleCorrection).clamp(82.0, 146.0).toDouble();

  double baselineCorrection(double correctedSize) =>
      correctedSize * (1 - alphaBottomNormalized);

  double bodyCenterOffsetX(double correctedSize) =>
      correctedSize * (alphaCenterXNormalized - .5);

  /// Offset from the sprite/runner centre to the left-most meaningful race
  /// pixel across all 12 authored frames. The race moves to the right, so
  /// this is the trailing edge that must clear the checker line.
  double trailingEdgeOffsetX(double correctedSize) =>
      correctedSize * (alphaLeftNormalized - .5);

  /// Offset from the sprite/runner centre to the right-most meaningful race
  /// pixel across all authored frames. This keeps the complete pet visible
  /// inside the post-finish runout rather than clamping its transparent box.
  double leadingEdgeOffsetX(double correctedSize) =>
      correctedSize * (alphaRightNormalized - .5);

  double nameOffset(double correctedSize) =>
      correctedSize * alphaTopNormalized + 18;
}

/// Presentation-only state.  The server still owns match status/result; this
/// state only describes how much of that result is visible on the race track.
enum PvpRacePresentationState {
  waiting,
  running,
  serverFinished,
  reconciling,
  reacting,
  showingResult,
}

class PvpRaceProgressMapper {
  const PvpRaceProgressMapper._();

  static double normalizeParticipant(
    PvpParticipantResponse participant, {
    required double fallbackProgress,
    int? finishTargetDistanceUnits,
  }) {
    final distance = participant.distanceUnits;
    final expected = participant.expectedDistanceUnits;
    final target = expected != null && expected > 0
        ? expected
        : finishTargetDistanceUnits;
    if (distance == null || distance <= 0 || target == null || target <= 0) {
      return fallbackProgress.clamp(0.0, 1.0).toDouble();
    }
    return (distance / target).clamp(0.0, 1.0).toDouble();
  }

  static int? finishTargetFromParticipants(
    Iterable<PvpParticipantResponse> participants,
  ) {
    final values = participants
        .map((participant) => participant.expectedDistanceUnits)
        .whereType<int>()
        .where((value) => value > 0)
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  static double approach({
    required double current,
    required double target,
    required double dtSeconds,
    double response = 8.0,
  }) {
    final safeTarget = target.clamp(0.0, 1.0).toDouble();
    final safeCurrent = current.clamp(0.0, 1.0).toDouble();
    if (safeTarget <= safeCurrent) return safeCurrent;
    final alpha = (1 - (-(response * dtSeconds)).exp()).clamp(0.0, 1.0);
    return (safeCurrent + (safeTarget - safeCurrent) * alpha)
        .clamp(0.0, safeTarget)
        .toDouble();
  }
}

extension on double {
  double exp() {
    // Small local helper keeps this pure file free from a math import in the
    // public API while still providing frame-rate independent smoothing.
    var term = 1.0;
    var sum = 1.0;
    for (var i = 1; i <= 12; i++) {
      term *= this / i;
      sum += term;
    }
    return sum;
  }
}

class PvpTrackCoordinateContract {
  const PvpTrackCoordinateContract._();

  static const double mapSourceWidth = 1440;
  static const double mapSourceHeight = 2560;
  static const double startLineSourceX = 510;
  // Shared geometry of the two production runout maps. The runner approaches
  // the stripe centre, then its trailing alpha edge clears the stripe exit.
  static const double finishStripeCenterSourceX = 870;
  static const double finishStripeExitSourceX = 912;

  static double finishLineScreenX({
    required double viewportWidth,
    required double viewportHeight,
    required double mapAlignmentX,
  }) {
    final geometry = PvpCoverGeometry.resolve(
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      sourceWidth: mapSourceWidth,
      sourceHeight: mapSourceHeight,
      alignmentX: mapAlignmentX,
    );
    return geometry.left + finishStripeExitSourceX * geometry.scale;
  }

  static double screenX({
    required double viewportWidth,
    required double viewportHeight,
    required double normalizedProgress,
    required double runnerWidth,
    double bodyCenterOffsetX = 0,
    double crossingAnchorOffsetX = 0,
    bool centeredMap = true,
    double? mapAlignmentX,
  }) {
    final scale = viewportHeight > 0
        ? (viewportWidth / mapSourceWidth > viewportHeight / mapSourceHeight
              ? viewportWidth / mapSourceWidth
              : viewportHeight / mapSourceHeight)
        : viewportWidth / mapSourceWidth;
    final renderedWidth = mapSourceWidth * scale;
    final mapLeft = mapAlignmentX == null
        ? (centeredMap ? (viewportWidth - renderedWidth) / 2 : 0.0)
        : (viewportWidth - renderedWidth) *
              ((mapAlignmentX.clamp(-1.0, 1.0) + 1) / 2);
    // The relocated stripe leaves enough room for the entire silhouette. The
    // runner's right edge stays eight logical pixels behind it at progress 0.
    final start = mapLeft + startLineSourceX * scale - runnerWidth / 2 - 8;
    final centreAtLine =
        mapLeft + finishStripeCenterSourceX * scale - bodyCenterOffsetX;
    // Production passes the authored alpha-left offset here, so the entire
    // meaningful silhouette (not merely its centre and not the transparent
    // 512px canvas) clears the stripe.
    final fullyCrossed =
        mapLeft + finishStripeExitSourceX * scale - crossingAnchorOffsetX + 4;
    final progress = normalizedProgress.clamp(0.0, 1.0).toDouble();
    final approach = start + (centreAtLine - start) * progress;
    // Preserve the readable approach composition, then complete the trailing
    // edge follow-through during the final 4% (~1.2 s of a 30 s race).
    final followThrough = ((progress - .96) / .04).clamp(0.0, 1.0).toDouble();
    final easedFollowThrough =
        followThrough * followThrough * (3 - 2 * followThrough);
    return approach + (fullyCrossed - centreAtLine) * easedFollowThrough;
  }
}

/// Geometric finish gate used by the presentation layer. Server result still
/// decides who won; this only decides when that result becomes visible.
bool hasPvpWinnerCrossedFinishLine({
  required String? resultCode,
  required double myTrailingEdgeX,
  required double opponentTrailingEdgeX,
  required double finishLineX,
}) {
  return switch (resultCode?.trim().toLowerCase()) {
    'win' => myTrailingEdgeX > finishLineX,
    'lose' => opponentTrailingEdgeX > finishLineX,
    'draw' =>
      myTrailingEdgeX > finishLineX && opponentTrailingEdgeX > finishLineX,
    _ => false,
  };
}
