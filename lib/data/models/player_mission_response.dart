class PlayerMissionRewardItemResponse {
  final String itemId;
  final String itemName;
  final int quantity;

  PlayerMissionRewardItemResponse({
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  factory PlayerMissionRewardItemResponse.fromJson(Map<String, dynamic> json) {
    return PlayerMissionRewardItemResponse(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 0,
    );
  }
}

class PlayerMissionItemResponse {
  final String missionId;
  final String? userMissionId;
  final String title;
  final String? description;
  final String missionTypeCode;
  final String metricCode;
  final int progressValue;
  final int targetValue;
  final int walletAmount;
  final List<PlayerMissionRewardItemResponse> rewardItems;
  final String statusCode;
  final bool canClaim;
  final String? claimedAt;

  PlayerMissionItemResponse({
    required this.missionId,
    this.userMissionId,
    required this.title,
    this.description,
    required this.missionTypeCode,
    required this.metricCode,
    required this.progressValue,
    required this.targetValue,
    required this.walletAmount,
    required this.rewardItems,
    required this.statusCode,
    required this.canClaim,
    this.claimedAt,
  });

  factory PlayerMissionItemResponse.fromJson(Map<String, dynamic> json) {
    final rewards = json['rewardItems'];
    return PlayerMissionItemResponse(
      missionId: json['missionId'] as String? ?? '',
      userMissionId: json['userMissionId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      missionTypeCode: json['missionTypeCode'] as String? ?? '',
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
                  (e) => PlayerMissionRewardItemResponse.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
      statusCode: json['statusCode'] as String? ?? '',
      canClaim: json['canClaim'] as bool? ?? false,
      claimedAt: json['claimedAt'] as String?,
    );
  }
}

class PlayerMissionListResponse {
  final List<PlayerMissionItemResponse> dailyMissions;
  final List<PlayerMissionItemResponse> overallMissions;

  PlayerMissionListResponse({
    required this.dailyMissions,
    required this.overallMissions,
  });

  factory PlayerMissionListResponse.fromJson(Map<String, dynamic> json) {
    List<PlayerMissionItemResponse> parseList(dynamic value) {
      if (value is! List) return [];
      return value
          .map(
            (e) =>
                PlayerMissionItemResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    return PlayerMissionListResponse(
      dailyMissions: parseList(json['dailyMissions']),
      overallMissions: parseList(json['overallMissions']),
    );
  }
}

class ClaimMissionRewardResponse {
  final String missionId;
  final String userMissionId;
  final int walletAmount;
  final int walletBalance;
  final String? claimedAt;

  ClaimMissionRewardResponse({
    required this.missionId,
    required this.userMissionId,
    required this.walletAmount,
    required this.walletBalance,
    this.claimedAt,
  });

  factory ClaimMissionRewardResponse.fromJson(Map<String, dynamic> json) {
    return ClaimMissionRewardResponse(
      missionId: json['missionId'] as String? ?? '',
      userMissionId: json['userMissionId'] as String? ?? '',
      walletAmount: json['walletAmount'] is int
          ? json['walletAmount'] as int
          : int.tryParse('${json['walletAmount']}') ?? 0,
      walletBalance: json['walletBalance'] is int
          ? json['walletBalance'] as int
          : int.tryParse('${json['walletBalance']}') ?? 0,
      claimedAt: json['claimedAt'] as String?,
    );
  }
}
