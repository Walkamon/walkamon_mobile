import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String petProductionManifestAsset =
    'assets/Mobile/pet_runtime_prod_v1/pet_runtime_manifest_v1.json';

enum PetSemanticState {
  idle,
  happy,
  hungry,
  sad,
  sleep,
  excited,
  feedEat,
  tapHello;

  String get wireName => switch (this) {
    PetSemanticState.feedEat => 'feed_eat',
    PetSemanticState.tapHello => 'tap_hello',
    _ => name,
  };

  bool get isAction => this == feedEat || this == tapHello;

  static PetSemanticState fromWire(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'happy' => happy,
      'hungry' || 'hunggry' => hungry,
      'sad' => sad,
      'sleep' || 'sleeping' => sleep,
      'excited' => excited,
      'feed' || 'feed_eat' || 'eat' => feedEat,
      'tap' || 'tap_hello' || 'hello' => tapHello,
      _ => idle,
    };
  }
}

enum PetMotionMode { ground, hover }

@immutable
class PetRuntimeInput {
  const PetRuntimeInput({
    required this.affinityCode,
    required this.stageNo,
    required this.state,
    this.actionSerial = 0,
  });

  final String affinityCode;
  final int stageNo;
  final PetSemanticState state;

  /// Monotonic serial that permits replaying the same one-shot action.
  final int actionSerial;

  String get formKey => resolvePetRuntimeFormKey(affinityCode, stageNo);

  PetRuntimeInput copyWith({
    String? affinityCode,
    int? stageNo,
    PetSemanticState? state,
    int? actionSerial,
  }) => PetRuntimeInput(
    affinityCode: affinityCode ?? this.affinityCode,
    stageNo: stageNo ?? this.stageNo,
    state: state ?? this.state,
    actionSerial: actionSerial ?? this.actionSerial,
  );

  @override
  bool operator ==(Object other) =>
      other is PetRuntimeInput &&
      other.affinityCode.trim().toLowerCase() ==
          affinityCode.trim().toLowerCase() &&
      other.stageNo == stageNo &&
      other.state == state &&
      other.actionSerial == actionSerial;

  @override
  int get hashCode => Object.hash(
    affinityCode.trim().toLowerCase(),
    stageNo,
    state,
    actionSerial,
  );
}

@immutable
class PetRuntimeClip {
  const PetRuntimeClip({
    required this.id,
    required this.sheet,
    required this.columns,
    required this.rows,
    required this.frameCount,
    required this.durations,
    required this.loop,
  });

  factory PetRuntimeClip.fromJson(Map<String, dynamic> json) {
    final durations = (json['durations'] as List? ?? const <dynamic>[])
        .whereType<num>()
        .map((value) => value.toDouble().clamp(1 / 240, 10.0))
        .toList(growable: false);
    final frameCount = (json['frameCount'] as num?)?.toInt() ?? 0;
    if (frameCount <= 0 || durations.length != frameCount) {
      throw const FormatException('Invalid production pet clip frame timing');
    }
    return PetRuntimeClip(
      id: json['id']?.toString() ?? '',
      sheet: json['sheet']?.toString() ?? '',
      columns: (json['columns'] as num?)?.toInt() ?? 0,
      rows: (json['rows'] as num?)?.toInt() ?? 0,
      frameCount: frameCount,
      durations: durations,
      loop: json['loop'] == true,
    );
  }

  final String id;
  final String sheet;
  final int columns;
  final int rows;
  final int frameCount;
  final List<double> durations;
  final bool loop;

  double get totalDuration => durations.fold(0, (sum, value) => sum + value);
}

@immutable
class PetRuntimeStateDefinition {
  const PetRuntimeStateDefinition({
    this.enter,
    this.loop,
    this.exit,
    this.action = const <PetRuntimeClip>[],
  });

  factory PetRuntimeStateDefinition.fromJson(Map<String, dynamic> json) =>
      PetRuntimeStateDefinition(
        enter: _readOptionalClip(json['enter']),
        loop: _readOptionalClip(json['loop']),
        exit: _readOptionalClip(json['exit']),
        action: (json['action'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (value) =>
                  PetRuntimeClip.fromJson(Map<String, dynamic>.from(value)),
            )
            .toList(growable: false),
      );

  final PetRuntimeClip? enter;
  final PetRuntimeClip? loop;
  final PetRuntimeClip? exit;
  final List<PetRuntimeClip> action;

  static PetRuntimeClip? _readOptionalClip(Object? value) {
    if (value is! Map) return null;
    return PetRuntimeClip.fromJson(Map<String, dynamic>.from(value));
  }
}

@immutable
class PetRuntimeFormDefinition {
  const PetRuntimeFormDefinition({
    required this.key,
    required this.motionMode,
    required this.homeCanvasScale,
    required this.states,
  });

  factory PetRuntimeFormDefinition.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    final rawStates = json['states'] as Map? ?? const <dynamic, dynamic>{};
    return PetRuntimeFormDefinition(
      key: key,
      motionMode: json['motionMode']?.toString() == 'hover'
          ? PetMotionMode.hover
          : PetMotionMode.ground,
      homeCanvasScale: ((json['homeCanvasScale'] as num?)?.toDouble() ?? 1.0)
          .clamp(0.55, 1.35),
      states: {
        for (final entry in rawStates.entries)
          PetSemanticState.fromWire(
            entry.key.toString(),
          ): PetRuntimeStateDefinition.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      },
    );
  }

  final String key;
  final PetMotionMode motionMode;
  final double homeCanvasScale;
  final Map<PetSemanticState, PetRuntimeStateDefinition> states;

  PetRuntimeStateDefinition stateOrIdle(PetSemanticState state) =>
      states[state] ?? states[PetSemanticState.idle]!;
}

@immutable
class PetRuntimeManifest {
  const PetRuntimeManifest({
    required this.runtimeSize,
    required this.baselineNormalized,
    required this.forms,
  });

  factory PetRuntimeManifest.fromJson(Map<String, dynamic> json) {
    if (json['production'] != true || json['candidateOnly'] == true) {
      throw const FormatException('Pet runtime manifest is not production');
    }
    final rawForms = json['forms'] as Map? ?? const <dynamic, dynamic>{};
    final forms = {
      for (final entry in rawForms.entries)
        entry.key.toString(): PetRuntimeFormDefinition.fromJson(
          entry.key.toString(),
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };
    if (forms.isEmpty) {
      throw const FormatException('Production pet manifest has no forms');
    }
    return PetRuntimeManifest(
      runtimeSize: (json['runtimeSize'] as num?)?.toInt() ?? 384,
      baselineNormalized:
          ((json['baselineNormalized'] as num?)?.toDouble() ?? 1.0).clamp(
            0.5,
            1.0,
          ),
      forms: forms,
    );
  }

  final int runtimeSize;
  final double baselineNormalized;
  final Map<String, PetRuntimeFormDefinition> forms;

  PetRuntimeFormDefinition formOrSprout(String formKey) =>
      forms[formKey] ?? forms['sprout_stage0']!;
}

class PetRuntimeManifestLoader {
  PetRuntimeManifestLoader({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Future<PetRuntimeManifest>? _cached;

  Future<PetRuntimeManifest> load() => _cached ??= _load();

  Future<PetRuntimeManifest> _load() async {
    final source = await _bundle.loadString(petProductionManifestAsset);
    return PetRuntimeManifest.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}

/// Stable mobile form identity. Legacy/DB normalization lives only here.
String resolvePetRuntimeFormKey(String affinityCode, int stageNo) {
  final normalized = affinityCode.trim().toLowerCase().replaceAll('-', '_');
  final affinity = switch (normalized) {
    'mam_non' || 'mầm_non' || 'mầm non' || 'sprout' => 'sprout',
    'nang_am' || 'nắng_ấm' || 'nắng ấm' || 'warm_sun' => 'warm_sun',
    'binh_minh' || 'bình_minh' || 'bình minh' || 'dawn' => 'dawn',
    'anh_trang' || 'ánh_trăng' || 'ánh trăng' || 'moonlight' => 'moonlight',
    _ => 'sprout',
  };
  if (affinity == 'sprout') return 'sprout_stage0';
  return '${affinity}_stage${stageNo.clamp(1, 2)}';
}
