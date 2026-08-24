class AnimationInfo {
  final String typeAnimation;
  final String animationUrl;

  AnimationInfo({required this.typeAnimation, required this.animationUrl});

  factory AnimationInfo.fromJson(Map<String, dynamic> json) {
    return AnimationInfo(
      typeAnimation: json['typeAnimation'] as String? ?? '',
      animationUrl: json['animationUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'typeAnimation': typeAnimation, 'animationUrl': animationUrl};
  }
}

class FriendSpiritResponse {
  final String userId;
  final String userName;
  final String petNickName;
  final String petName;
  final int level;
  final int currentExp;
  final int maxExp;
  final int currentEnergy;
  final int maxEnergy;
  final int currentBond;
  final int maxBond;
  final int currentLifeForce;
  final int maxLifeForce;
  final String stageName;
  final String stageImage;
  final List<AnimationInfo> animations;

  FriendSpiritResponse({
    required this.userId,
    required this.userName,
    required this.petNickName,
    required this.petName,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentBond,
    required this.maxBond,
    required this.currentLifeForce,
    required this.maxLifeForce,
    required this.stageName,
    required this.stageImage,
    required this.animations,
  });

  factory FriendSpiritResponse.fromJson(Map<String, dynamic> json) {
    return FriendSpiritResponse(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      petNickName: json['petNickName'] as String? ?? '',
      petName: json['petName'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      currentExp: json['currentExp'] as int? ?? 0,
      maxExp: json['maxExp'] as int? ?? 100,
      currentEnergy: json['currentEnergy'] as int? ?? 0,
      maxEnergy: json['maxEnergy'] as int? ?? 100,
      currentBond: json['currentBond'] as int? ?? 0,
      maxBond: json['maxBond'] as int? ?? 100,
      currentLifeForce: json['currentLifeForce'] as int? ?? 0,
      maxLifeForce: json['maxLifeForce'] as int? ?? 100,
      stageName: json['stageName'] as String? ?? '',
      stageImage: json['stageImage'] as String? ?? '',
      animations:
          (json['animations'] as List<dynamic>?)
              ?.map((e) => AnimationInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'petNickName': petNickName,
      'petName': petName,
      'level': level,
      'currentExp': currentExp,
      'maxExp': maxExp,
      'currentEnergy': currentEnergy,
      'maxEnergy': maxEnergy,
      'currentBond': currentBond,
      'maxBond': maxBond,
      'currentLifeForce': currentLifeForce,
      'maxLifeForce': maxLifeForce,
      'stageName': stageName,
      'stageImage': stageImage,
      'animations': animations.map((e) => e.toJson()).toList(),
    };
  }
}
