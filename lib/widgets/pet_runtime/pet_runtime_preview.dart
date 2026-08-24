import 'package:flutter/material.dart';

import 'pet_production_game.dart';
import 'pet_renderer_host.dart';
import 'pet_runtime_models.dart';

export 'pet_runtime_models.dart'
    show
        PetMotionMode,
        PetRuntimeInput,
        PetSemanticState,
        resolvePetRuntimeFormKey;

class PetRuntimePreview extends StatelessWidget {
  const PetRuntimePreview({
    super.key,
    this.affinityCode = 'sprout',
    this.stageNo = 0,
    this.animationType = 'idle',
    this.assetReference,
    this.compact = false,
    this.height = 180,
    this.actionSerial = 0,
    this.showDebugOverlay = false,
    this.onGameCreated,
  });

  final String affinityCode;
  final int stageNo;
  final String animationType;
  final String? assetReference;
  final bool compact;
  final double height;
  final int actionSerial;
  final bool showDebugOverlay;
  final ValueChanged<PetProductionGame>? onGameCreated;

  @override
  Widget build(BuildContext context) {
    final reference = parsePetRuntimeAssetReference(assetReference);
    final resolvedAffinity = reference?.affinityCode ?? affinityCode;
    final resolvedStage = reference?.stageNo ?? stageNo;
    final resolvedAnimation = reference?.animationType ?? animationType;
    final input = PetRuntimeInput(
      affinityCode: resolvedAffinity,
      stageNo: resolvedStage,
      state: PetSemanticState.fromWire(resolvedAnimation),
      actionSerial: actionSerial,
    );
    final renderer = PetRendererHost(
      input: input,
      showDebugOverlay: showDebugOverlay,
      onGameCreated: onGameCreated,
    );

    if (compact) {
      return SizedBox.square(dimension: height, child: renderer);
    }

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${input.formKey} · ${input.state.wireName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Expanded(child: renderer),
        ],
      ),
    );
  }
}

class PetRuntimeAssetReference {
  const PetRuntimeAssetReference({
    required this.affinityCode,
    required this.stageNo,
    required this.animationType,
  });

  final String affinityCode;
  final int stageNo;
  final String animationType;
}

PetRuntimeAssetReference? parsePetRuntimeAssetReference(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.scheme.toLowerCase() != 'asset') return null;
  if (uri.host.toLowerCase() != 'pet-runtime-v7.2') return null;
  final segments = uri.pathSegments
      .where((segment) => segment.trim().isNotEmpty)
      .toList(growable: false);
  if (segments.length < 3) return null;
  final affinityCode = segments[0].trim().toLowerCase();
  if (!const {
    'sprout',
    'warm_sun',
    'dawn',
    'moonlight',
  }.contains(affinityCode)) {
    return null;
  }
  final match = RegExp(
    r'^stage(\d+)$',
    caseSensitive: false,
  ).firstMatch(segments[1]);
  final stageNo = int.tryParse(match?.group(1) ?? '');
  if (stageNo == null) return null;
  return PetRuntimeAssetReference(
    affinityCode: affinityCode,
    stageNo: stageNo,
    animationType: segments.sublist(2).join('_').toLowerCase(),
  );
}

/// Backward-compatible exact semantic resolver for evolution API references.
/// Production playback uses [PetRuntimeManifest] rather than this V4 key.
String resolvePetRuntimeClipKey({
  required Map<String, dynamic> animations,
  required String formKey,
  required String affinityCode,
  required String animationType,
}) {
  final semantic = PetSemanticState.fromWire(animationType);
  final normalized = semantic.wireName;
  final candidates = <String>[
    if (semantic == PetSemanticState.idle) '${formKey}_idle_front',
    if (semantic == PetSemanticState.hungry) '${formKey}_hungry_loop',
    if (semantic == PetSemanticState.sad) '${formKey}_sad_loop',
    if (semantic == PetSemanticState.sleep) '${formKey}_sleep_loop',
    if (semantic == PetSemanticState.excited) '${formKey}_excited_loop',
    '${formKey}_$normalized',
    '${formKey}_idle_front',
  ];
  return candidates.firstWhere(
    animations.containsKey,
    orElse: () => '${formKey}_idle_front',
  );
}
