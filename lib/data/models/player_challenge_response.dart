class PlayerChallengeRewardItemResponse {
  final String itemId;
  final String itemName;
  final int quantity;

  PlayerChallengeRewardItemResponse({
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  factory PlayerChallengeRewardItemResponse.fromJson(Map<String, dynamic> json) {
    return PlayerChallengeRewardItemResponse(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 0,
    );
  }
}

class PlayerChallengeResponse {
  final String userMissionId;
  final String challengeId;
  final String title;
  final String? description;
  final String metricCode;
  final int progressValue;
  final int targetValue;
  final int walletAmount;
  final List<PlayerChallengeRewardItemResponse> rewardItems;
  final bool isCancelable;
  final String statusCode;
  final String? assignedAt;

  PlayerChallengeResponse({
    required this.userMissionId,
    required this.challengeId,
    required this.title,
    this.description,
    required this.metricCode,
    required this.progressValue,
    required this.targetValue,
    required this.walletAmount,
    required this.rewardItems,
    required this.isCancelable,
    required this.statusCode,
    this.assignedAt,
  });

  factory PlayerChallengeResponse.fromJson(Map<String, dynamic> json) {
    final rewards = json['rewardItems'];
    return PlayerChallengeResponse(
      userMissionId: json['userMissionId'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      metricCode: json['metricCode'] as String? ?? '',
      progressValue: json['progressValue'] is int
          ? json['progressValue'] as int
          : int.tryParse('${json['progressValue']}') ?? 0,
      targetValue: json['targetValue'] is int
          ? json['targetValue'] as int
          : int.tryParse('${json['targetValue']}') ?? 0,
      walletAmount: json['walletAmount'] is int
          ? json['walletAmount'] as int
          : int.tryParse('${json['walletAmount']}') ?? 0,
      rewardItems: rewards is List
          ? rewards
              .map(
                (e) => PlayerChallengeRewardItemResponse.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList()
          : [],
      isCancelable: json['isCancelable'] as bool? ?? false,
      statusCode: json['statusCode'] as String? ?? '',
      assignedAt: json['assignedAt'] as String?,
    );
  }
}

class PlayerChallengeStateResponse {
  final int cancelLimit;
  final int cancelUsed;
  final int cancelRemaining;
  final PlayerChallengeResponse? currentChallenge;

  PlayerChallengeStateResponse({
    required this.cancelLimit,
    required this.cancelUsed,
    required this.cancelRemaining,
    this.currentChallenge,
  });

  factory PlayerChallengeStateResponse.fromJson(Map<String, dynamic> json) {
    return PlayerChallengeStateResponse(
      cancelLimit: json['cancelLimit'] is int
          ? json['cancelLimit'] as int
          : int.tryParse('${json['cancelLimit']}') ?? 3,
      cancelUsed: json['cancelUsed'] is int
          ? json['cancelUsed'] as int
          : int.tryParse('${json['cancelUsed']}') ?? 0,
      cancelRemaining: json['cancelRemaining'] is int
          ? json['cancelRemaining'] as int
          : int.tryParse('${json['cancelRemaining']}') ?? 3,
      currentChallenge: json['currentChallenge'] is Map<String, dynamic>
          ? PlayerChallengeResponse.fromJson(
              json['currentChallenge'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class CancelPlayerChallengeResponse {
  final String userMissionId;
  final String statusCode;
  final int cancelLimit;
  final int cancelUsed;
  final int cancelRemaining;

  CancelPlayerChallengeResponse({
    required this.userMissionId,
    required this.statusCode,
    required this.cancelLimit,
    required this.cancelUsed,
    required this.cancelRemaining,
  });

  factory CancelPlayerChallengeResponse.fromJson(Map<String, dynamic> json) {
    return CancelPlayerChallengeResponse(
      userMissionId: json['userMissionId'] as String? ?? '',
      statusCode: json['statusCode'] as String? ?? '',
      cancelLimit: json['cancelLimit'] is int
          ? json['cancelLimit'] as int
          : int.tryParse('${json['cancelLimit']}') ?? 3,
      cancelUsed: json['cancelUsed'] is int
          ? json['cancelUsed'] as int
          : int.tryParse('${json['cancelUsed']}') ?? 0,
      cancelRemaining: json['cancelRemaining'] is int
          ? json['cancelRemaining'] as int
          : int.tryParse('${json['cancelRemaining']}') ?? 0,
    );
  }
}
