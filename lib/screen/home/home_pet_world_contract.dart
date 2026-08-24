import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum HomePetContactMode { ground, hover }

@immutable
class HomePetSceneContract {
  const HomePetSceneContract({
    required this.backgroundId,
    required this.contactMode,
    required this.contactYNormalized,
    required this.safeHorizontalRange,
    required this.allowedPetScaleRange,
    required this.shadowScale,
    required this.shadowOpacity,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.sourceAspectSize = const Size(9, 16),
  });

  final String backgroundId;
  final HomePetContactMode contactMode;
  final double contactYNormalized;
  final BoxFit fit;
  final Alignment alignment;

  /// The portrait masters are all 9:16. A ratio-sized source keeps the
  /// projection independent from whether the selected master is 900 or 1440
  /// pixels wide.
  final Size sourceAspectSize;
  final ({double min, double max}) safeHorizontalRange;
  final ({double min, double max}) allowedPetScaleRange;
  final double shadowScale;
  final double shadowOpacity;
}

const Map<String, HomePetSceneContract> _sceneContracts = {
  'sprout': HomePetSceneContract(
    backgroundId: 'home_sprout',
    contactMode: HomePetContactMode.ground,
    contactYNormalized: 0.635,
    safeHorizontalRange: (min: 0.30, max: 0.70),
    allowedPetScaleRange: (min: 0.91, max: 1.0),
    shadowScale: 0.72,
    shadowOpacity: 0.20,
  ),
  'warm_sun': HomePetSceneContract(
    backgroundId: 'home_warm_sun',
    contactMode: HomePetContactMode.ground,
    contactYNormalized: 0.625,
    safeHorizontalRange: (min: 0.29, max: 0.71),
    allowedPetScaleRange: (min: 0.91, max: 1.0),
    shadowScale: 0.72,
    shadowOpacity: 0.20,
  ),
  'dawn': HomePetSceneContract(
    backgroundId: 'home_dawn',
    contactMode: HomePetContactMode.hover,
    contactYNormalized: 0.585,
    safeHorizontalRange: (min: 0.31, max: 0.69),
    allowedPetScaleRange: (min: 0.91, max: 1.0),
    shadowScale: 0.55,
    shadowOpacity: 0.10,
  ),
  'moonlight': HomePetSceneContract(
    backgroundId: 'home_moonlight',
    contactMode: HomePetContactMode.ground,
    contactYNormalized: 0.605,
    safeHorizontalRange: (min: 0.30, max: 0.70),
    allowedPetScaleRange: (min: 0.91, max: 1.0),
    shadowScale: 0.72,
    shadowOpacity: 0.20,
  ),
};

HomePetSceneContract resolveHomePetSceneContract(String affinityCode) {
  final normalized = affinityCode.trim().toLowerCase();
  final canonical = switch (normalized) {
    'mam_non' => 'sprout',
    'nang_am' => 'warm_sun',
    'binh_minh' => 'dawn',
    'anh_trang' => 'moonlight',
    _ => normalized,
  };
  return _sceneContracts[canonical] ?? _sceneContracts['sprout']!;
}

/// Projects a source-normalized point through the exact [BoxFit] and crop
/// used by the Home background. This prevents source coordinates from being
/// applied directly to a cropped viewport.
Offset projectHomeSourcePoint({
  required Offset normalizedSourcePoint,
  required Size viewport,
  required HomePetSceneContract contract,
}) {
  if (viewport.isEmpty) return Offset.zero;
  final source = contract.sourceAspectSize;
  final fitted = applyBoxFit(contract.fit, source, viewport);
  final sourceRect = contract.alignment.inscribe(
    fitted.source,
    Offset.zero & source,
  );
  final destinationRect = contract.alignment.inscribe(
    fitted.destination,
    Offset.zero & viewport,
  );
  final sourcePoint = Offset(
    normalizedSourcePoint.dx.clamp(0.0, 1.0) * source.width,
    normalizedSourcePoint.dy.clamp(0.0, 1.0) * source.height,
  );
  return Offset(
    destinationRect.left +
        (sourcePoint.dx - sourceRect.left) /
            sourceRect.width *
            destinationRect.width,
    destinationRect.top +
        (sourcePoint.dy - sourceRect.top) /
            sourceRect.height *
            destinationRect.height,
  );
}

double homePetLogicalSize(Size viewport, HomePetSceneContract contract) {
  final unscaled = (viewport.width * 0.47).clamp(164.0, 180.0);
  return unscaled.clamp(
    180 * contract.allowedPetScaleRange.min,
    180 * contract.allowedPetScaleRange.max,
  );
}
