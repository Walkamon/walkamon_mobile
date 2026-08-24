class PetOverviewResponse {
  const PetOverviewResponse({
    required this.petId,
    required this.nickname,
    required this.formName,
    required this.affinityCode,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentLifeForce,
    required this.maxLifeForce,
    required this.currentBond,
    required this.maxBond,
    required this.stageNo,
    required this.stageName,
    required this.animationType,
    required this.canEvolve,
    required this.nextEvolutionLevel,
  });

  final String petId;
  final String nickname;
  final String formName;
  final String affinityCode;
  final int level;
  final int currentExp;
  final int maxExp;
  final int currentEnergy;
  final int maxEnergy;
  final int currentLifeForce;
  final int maxLifeForce;
  final int currentBond;
  final int maxBond;
  final int stageNo;
  final String stageName;
  final String animationType;
  final bool canEvolve;
  final int nextEvolutionLevel;

  factory PetOverviewResponse.fromJson(Map<String, dynamic> json) {
    return PetOverviewResponse(
      petId: json['petId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      formName: json['formName']?.toString() ?? '',
      affinityCode: json['affinityCode']?.toString() ?? '',
      level: int.tryParse(json['level']?.toString() ?? '0') ?? 0,
      currentExp: int.tryParse(json['currentExp']?.toString() ?? '0') ?? 0,
      maxExp: int.tryParse(json['maxExp']?.toString() ?? '0') ?? 0,
      currentEnergy:
          int.tryParse(json['currentEnergy']?.toString() ?? '0') ?? 0,
      maxEnergy: int.tryParse(json['maxEnergy']?.toString() ?? '0') ?? 0,
      currentLifeForce:
          int.tryParse(json['currentLifeForce']?.toString() ?? '0') ?? 0,
      maxLifeForce: int.tryParse(json['maxLifeForce']?.toString() ?? '0') ?? 0,
      currentBond: int.tryParse(json['currentBond']?.toString() ?? '0') ?? 0,
      maxBond: int.tryParse(json['maxBond']?.toString() ?? '0') ?? 0,
      stageNo: int.tryParse(json['stageNo']?.toString() ?? '0') ?? 0,
      stageName: json['stageName']?.toString() ?? '',
      animationType: json['animationType']?.toString() ?? '',
      canEvolve:
          json['canEvolve'] == true ||
          json['canEvolve']?.toString().toLowerCase() == 'true',
      nextEvolutionLevel:
          int.tryParse(json['nextEvolutionLevel']?.toString() ?? '0') ?? 0,
    );
  }
}

class PetEvolutionStageResponse {
  const PetEvolutionStageResponse({
    required this.stageId,
    required this.stageNo,
    required this.stageName,
    required this.stateUrl,
    required this.requiredLevel,
    required this.isCurrent,
    required this.isUnlocked,
    required this.animations,
  });

  final String stageId;
  final int stageNo;
  final String stageName;
  final String stateUrl;
  final int requiredLevel;
  final bool isCurrent;
  final bool isUnlocked;
  final List<PetEvolutionAnimationResponse> animations;

  factory PetEvolutionStageResponse.fromJson(Map<String, dynamic> json) {
    final animationsJson = json['animations'];
    return PetEvolutionStageResponse(
      stageId: json['stageId']?.toString() ?? '',
      stageNo: int.tryParse(json['stageNo']?.toString() ?? '0') ?? 0,
      stageName: json['stageName']?.toString() ?? '',
      stateUrl: json['stateUrl']?.toString() ?? '',
      requiredLevel:
          int.tryParse(json['requiredLevel']?.toString() ?? '0') ?? 0,
      isCurrent:
          json['isCurrent'] == true ||
          json['isCurrent']?.toString().toLowerCase() == 'true',
      isUnlocked:
          json['isUnlocked'] == true ||
          json['isUnlocked']?.toString().toLowerCase() == 'true',
      animations: animationsJson is List
          ? animationsJson
                .whereType<Map>()
                .map(
                  (item) => PetEvolutionAnimationResponse.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <PetEvolutionAnimationResponse>[],
    );
  }
}

class PetEvolutionAnimationResponse {
  const PetEvolutionAnimationResponse({
    required this.typeAnimation,
    required this.animationUrl,
  });

  final String typeAnimation;
  final String animationUrl;

  factory PetEvolutionAnimationResponse.fromJson(Map<String, dynamic> json) {
    return PetEvolutionAnimationResponse(
      typeAnimation: json['typeAnimation']?.toString() ?? '',
      animationUrl: json['animationUrl']?.toString() ?? '',
    );
  }
}

class PetEvolutionHistoryResponse {
  const PetEvolutionHistoryResponse({
    required this.petName,
    required this.stageName,
    required this.stageNo,
    required this.level,
    required this.evolvedAt,
  });

  final String petName;
  final String stageName;
  final int stageNo;
  final int level;
  final String evolvedAt;

  factory PetEvolutionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PetEvolutionHistoryResponse(
      petName: json['petName']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? '',
      stageNo: int.tryParse(json['stageNo']?.toString() ?? '0') ?? 0,
      level: int.tryParse(json['level']?.toString() ?? '0') ?? 0,
      evolvedAt: json['evolvedAt']?.toString() ?? '',
    );
  }
}

class PetCurrentAnimationResponse {
  const PetCurrentAnimationResponse({
    required this.animationType,
    required this.animationUrl,
    required this.stageNo,
    required this.stageName,
  });

  final String animationType;
  final String animationUrl;
  final int stageNo;
  final String stageName;

  factory PetCurrentAnimationResponse.fromJson(Map<String, dynamic> json) {
    return PetCurrentAnimationResponse(
      animationType: json['animationType']?.toString() ?? '',
      animationUrl: json['animationUrl']?.toString() ?? '',
      stageNo: int.tryParse(json['stageNo']?.toString() ?? '0') ?? 0,
      stageName: json['stageName']?.toString() ?? '',
    );
  }
}

class PetEvolutionOptionResponse {
  const PetEvolutionOptionResponse({
    required this.petId,
    required this.petName,
    required this.stateUrl,
    required this.requiredLevel,
  });

  final String petId;
  final String petName;
  final String stateUrl;
  final int requiredLevel;

  factory PetEvolutionOptionResponse.fromJson(Map<String, dynamic> json) {
    return PetEvolutionOptionResponse(
      petId: json['petId']?.toString() ?? '',
      petName: json['petName']?.toString() ?? '',
      stateUrl: json['stateUrl']?.toString() ?? '',
      requiredLevel:
          int.tryParse(json['requiredLevel']?.toString() ?? '0') ?? 0,
    );
  }
}

// ─── Preview Models ────────────────────────────────────────────────────────

class PetEvolutionPreviewStageResponse {
  const PetEvolutionPreviewStageResponse({
    required this.stageNo,
    required this.stageName,
    required this.stageImage,
    required this.requiredLevel,
    required this.animations,
  });

  final int stageNo;
  final String stageName;
  final String stageImage;
  final int requiredLevel;
  final List<PetEvolutionAnimationResponse> animations;

  factory PetEvolutionPreviewStageResponse.fromJson(Map<String, dynamic> json) {
    final animationsJson = json['animations'];
    return PetEvolutionPreviewStageResponse(
      stageNo: int.tryParse(json['stageNo']?.toString() ?? '0') ?? 0,
      stageName: json['stageName']?.toString() ?? '',
      stageImage: json['stageImage']?.toString() ?? '',
      requiredLevel:
          int.tryParse(json['requiredLevel']?.toString() ?? '0') ?? 0,
      animations: animationsJson is List
          ? animationsJson
                .whereType<Map>()
                .map(
                  (item) => PetEvolutionAnimationResponse.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <PetEvolutionAnimationResponse>[],
    );
  }
}

class PetEvolutionPreviewResponse {
  const PetEvolutionPreviewResponse({
    required this.petId,
    required this.petName,
    required this.stages,
  });

  final String petId;
  final String petName;
  final List<PetEvolutionPreviewStageResponse> stages;

  factory PetEvolutionPreviewResponse.fromJson(Map<String, dynamic> json) {
    final stagesJson = json['stages'];
    return PetEvolutionPreviewResponse(
      petId: json['petId']?.toString() ?? '',
      petName: json['petName']?.toString() ?? '',
      stages: stagesJson is List
          ? stagesJson
                .whereType<Map>()
                .map(
                  (item) => PetEvolutionPreviewStageResponse.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <PetEvolutionPreviewStageResponse>[],
    );
  }
}
