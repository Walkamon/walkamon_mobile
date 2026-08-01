import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../common/app_icon.dart';

/// Lightweight pet visual backed by the V7.2 runtime catalog.
///
/// Master atlas pages (~2.36 GiB) are intentionally not loaded here. Per
/// `docs/PET_ANIMATION_FLAME_IMPLEMENTATION_GUIDE.md`, Home/Spirit should use
/// catalog fallback art until a production pack (`pet_runtime_prod_v1`) exists.
class PetRuntimePreview extends StatefulWidget {
  const PetRuntimePreview({
    super.key,
    this.affinityCode = 'sprout',
    this.stageNo = 0,
    this.animationType = 'idle',
    this.assetReference,
    this.compact = false,
    this.height = 180,
  });

  final String affinityCode;
  final int stageNo;
  final String animationType;

  /// Logical backend reference such as
  /// `asset://pet-runtime-v7.2/dawn/stage1/idle_front`.
  /// When valid, it takes precedence over affinity/stage/animation fallbacks.
  final String? assetReference;
  final bool compact;
  final double height;

  @override
  State<PetRuntimePreview> createState() => _PetRuntimePreviewState();
}

class _PetRuntimePreviewState extends State<PetRuntimePreview> {
  bool _isLoading = true;
  String? _error;
  String? _fallbackAsset;
  String? _resolvedFormKey;
  String? _resolvedClipKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PetRuntimePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.affinityCode != widget.affinityCode ||
        oldWidget.stageNo != widget.stageNo ||
        oldWidget.animationType != widget.animationType ||
        oldWidget.assetReference != widget.assetReference) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _fallbackAsset = null;
      _resolvedFormKey = null;
      _resolvedClipKey = null;
    });

    try {
      final reference = parsePetRuntimeAssetReference(widget.assetReference);
      final affinityCode = reference?.affinityCode ?? widget.affinityCode;
      final stageNo = reference?.stageNo ?? widget.stageNo;
      final animationType = reference?.animationType ?? widget.animationType;
      final formKey = resolvePetRuntimeFormKey(affinityCode, stageNo);

      final catalogJson = await rootBundle.loadString(
        AppAssets.petRuntimeCatalogV1,
      );
      final parsedCatalog = jsonDecode(catalogJson) as Map<String, dynamic>;
      final forms = (parsedCatalog['forms'] as List?) ?? const <dynamic>[];
      final form = forms.whereType<Map>().cast<Map>().firstWhere(
        (entry) => entry['key']?.toString() == formKey,
        orElse: () => const <String, dynamic>{},
      );

      if (form.isEmpty) {
        throw StateError('No catalog form found for $formKey');
      }

      String? fallbackAsset;
      final formFallbacks = (form['fallbackAssets'] as List?) ?? const [];
      if (formFallbacks.isNotEmpty) {
        fallbackAsset = formFallbacks.first.toString();
      }

      final manifestAsset = form['manifestAsset']?.toString();
      String? clipKey;
      if (manifestAsset != null && manifestAsset.isNotEmpty) {
        try {
          final manifestJson = await rootBundle.loadString(manifestAsset);
          final parsedManifest =
              jsonDecode(manifestJson) as Map<String, dynamic>;
          final animations =
              parsedManifest['animations'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          clipKey = resolvePetRuntimeClipKey(
            animations: animations,
            formKey: formKey,
            affinityCode: affinityCode,
            animationType: animationType,
          );
          final clip = animations[clipKey] as Map<String, dynamic>?;
          final clipFallback = clip?['fallbackAsset']?.toString();
          if (clipFallback != null && clipFallback.isNotEmpty) {
            fallbackAsset = clipFallback;
          }
        } on FlutterError {
          // Manifest may be omitted from the slim asset pack; catalog fallback
          // is enough for Home/Spirit until the production atlas pack lands.
        }
      }

      if (fallbackAsset == null || fallbackAsset.isEmpty) {
        throw StateError('No fallback asset found for $formKey');
      }

      // Ensure the fallback itself is present in the asset bundle.
      await rootBundle.load(fallbackAsset);

      if (!mounted) return;
      setState(() {
        _resolvedFormKey = formKey;
        _resolvedClipKey = clipKey;
        _fallbackAsset = fallbackAsset;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null || _fallbackAsset == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: AppIcon(
            Icons.spa_outlined,
            size: widget.compact ? 64 : 56,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
          ),
        ),
      );
    }

    final image = Image.asset(
      _fallbackAsset!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => AppIcon(
        Icons.spa_outlined,
        size: widget.compact ? 64 : 56,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
      ),
    );

    if (widget.compact) {
      return SizedBox(
        height: widget.height,
        width: widget.height,
        child: image,
      );
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pet Runtime',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${_resolvedFormKey ?? widget.affinityCode}'
            ' • ${widget.animationType}'
            '${_resolvedClipKey != null ? ' • $_resolvedClipKey' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Expanded(child: Center(child: image)),
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

/// Parses backend logical pet-runtime keys without treating them as Flutter
/// bundle paths. Returns null for regular HTTP URLs and legacy asset paths.
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
  const supportedAffinities = {'sprout', 'warm_sun', 'dawn', 'moonlight'};
  if (!supportedAffinities.contains(affinityCode)) return null;

  final stageMatch = RegExp(
    r'^stage(\d+)$',
    caseSensitive: false,
  ).firstMatch(segments[1]);
  final stageNo = int.tryParse(stageMatch?.group(1) ?? '');
  if (stageNo == null) return null;

  return PetRuntimeAssetReference(
    affinityCode: affinityCode,
    stageNo: stageNo,
    animationType: segments.sublist(2).join('_').toLowerCase(),
  );
}

/// Maps API affinity/stage onto a catalog form key.
String resolvePetRuntimeFormKey(String affinityCode, int stageNo) {
  final normalizedAffinity = affinityCode.trim().isEmpty
      ? 'sprout'
      : affinityCode.trim().toLowerCase();

  switch (normalizedAffinity) {
    case 'sprout':
      // Starter is always asset stage 0, even when DB returns stage_no = 1.
      return 'sprout_stage0';
    case 'warm_sun':
    case 'dawn':
    case 'moonlight':
      final clampedStage = stageNo.clamp(1, 2);
      return '${normalizedAffinity}_stage$clampedStage';
    default:
      return 'sprout_stage0';
  }
}

/// Resolves a coarse server animation type onto a V4 clip id.
String resolvePetRuntimeClipKey({
  required Map<String, dynamic> animations,
  required String formKey,
  required String affinityCode,
  required String animationType,
}) {
  final normalizedType = animationType.trim().isEmpty
      ? 'idle'
      : animationType.trim().toLowerCase();

  final candidates = <String>[
    if (normalizedType == 'idle') ...[
      '${formKey}_idle_front',
      '${formKey}_idle',
    ],
    if (normalizedType == 'sleep') ...[
      '${formKey}_sleep_loop',
      '${formKey}_sleep_enter',
      '${formKey}_sleep',
    ],
    if (normalizedType == 'hungry') ...[
      '${formKey}_hungry_loop',
      '${formKey}_hungry_enter',
      '${formKey}_hungry',
    ],
    if (normalizedType == 'sad') ...[
      '${formKey}_sad_loop',
      '${formKey}_sad_enter',
      '${formKey}_sad',
    ],
    if (normalizedType == 'excited') ...[
      '${formKey}_excited_loop',
      '${formKey}_excited_enter',
      '${formKey}_excited',
    ],
    '${formKey}_$normalizedType',
    '${formKey}_idle_front',
    '${formKey}_idle',
    '${affinityCode}_idle_front',
    'idle_front',
  ];

  for (final candidate in candidates) {
    if (animations.containsKey(candidate)) {
      return candidate;
    }
  }

  return animations.keys.isEmpty ? 'idle_front' : animations.keys.first;
}
