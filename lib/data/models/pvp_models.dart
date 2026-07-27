class PvpParticipantResponse {
  final String participantTypeCode;
  final String? userId;
  final String? matchPlayerId;
  final String? botProfileId;
  final String? displayName;
  final String? avatarUrl;
  final int? score;
  final int? validatedSteps;
  final int? distanceUnits;
  final int? speedMultiplierBps;
  final String? spiritAffinityCode;
  final int? passiveSpeedBps;
  final String? resultCode;

  PvpParticipantResponse({
    required this.participantTypeCode,
    this.userId,
    this.matchPlayerId,
    this.botProfileId,
    this.displayName,
    this.avatarUrl,
    this.score,
    this.validatedSteps,
    this.distanceUnits,
    this.speedMultiplierBps,
    this.spiritAffinityCode,
    this.passiveSpeedBps,
    this.resultCode,
  });

  factory PvpParticipantResponse.fromJson(Map<String, dynamic> json) {
    return PvpParticipantResponse(
      participantTypeCode: json['participantTypeCode'] as String? ?? '',
      userId: json['userId'] as String?,
      matchPlayerId: json['matchPlayerId'] as String?,
      botProfileId: json['botProfileId'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num?)?.toInt(),
      validatedSteps: (json['validatedSteps'] as num?)?.toInt(),
      distanceUnits: (json['distanceUnits'] as num?)?.toInt(),
      speedMultiplierBps: (json['speedMultiplierBps'] as num?)?.toInt(),
      spiritAffinityCode: json['spiritAffinityCode'] as String?,
      passiveSpeedBps: (json['passiveSpeedBps'] as num?)?.toInt(),
      resultCode: json['resultCode'] as String?,
    );
  }
}

class PvpMatchResponse {
  final String matchId;
  final String matchTypeCode;
  final String statusCode;
  final String? sourceCode;
  final DateTime? serverTime;
  final DateTime? createdAt;
  final DateTime? countdownEndsAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? settlementEndsAt;
  final int? lastEventSequence;
  final List<PvpParticipantResponse> participants;

  PvpMatchResponse({
    required this.matchId,
    required this.matchTypeCode,
    required this.statusCode,
    this.sourceCode,
    this.serverTime,
    this.createdAt,
    this.countdownEndsAt,
    this.startedAt,
    this.endedAt,
    this.settlementEndsAt,
    this.lastEventSequence,
    required this.participants,
  });

  factory PvpMatchResponse.fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List<dynamic>? ?? [];
    return PvpMatchResponse(
      matchId: json['matchId'] as String? ?? '',
      matchTypeCode: json['matchTypeCode'] as String? ?? '',
      statusCode: json['statusCode'] as String? ?? '',
      sourceCode: json['sourceCode'] as String?,
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'] as String)?.toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal()
          : null,
      countdownEndsAt: json['countdownEndsAt'] != null
          ? DateTime.tryParse(json['countdownEndsAt'] as String)?.toLocal()
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)?.toLocal()
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)?.toLocal()
          : null,
      settlementEndsAt: json['settlementEndsAt'] != null
          ? DateTime.tryParse(json['settlementEndsAt'] as String)?.toLocal()
          : null,
      lastEventSequence: (json['lastEventSequence'] as num?)?.toInt(),
      participants: participantsList
          .map(
            (e) => PvpParticipantResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class PvpMatchmakingStatusResponse {
  final String activityType;
  final String statusCode;
  final String? matchId;
  final DateTime? queuedAt;
  final DateTime? botFallbackAt;
  final DateTime? serverTime;

  PvpMatchmakingStatusResponse({
    required this.activityType,
    required this.statusCode,
    this.matchId,
    this.queuedAt,
    this.botFallbackAt,
    this.serverTime,
  });

  factory PvpMatchmakingStatusResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseUtc(String? value) =>
        value != null ? DateTime.tryParse(value)?.toUtc() : null;

    return PvpMatchmakingStatusResponse(
      activityType: json['activityType'] as String? ?? 'idle',
      statusCode: json['statusCode'] as String? ?? 'idle',
      matchId: json['matchId'] as String?,
      queuedAt: parseUtc(json['queuedAt'] as String?),
      botFallbackAt: parseUtc(json['botFallbackAt'] as String?),
      serverTime: parseUtc(json['serverTime'] as String?),
    );
  }
}

class PvpUserResponse {
  final String userId;
  final String username;
  final String? avatarUrl;

  PvpUserResponse({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  factory PvpUserResponse.fromJson(Map<String, dynamic> json) {
    return PvpUserResponse(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class PvpInviteResponse {
  final String inviteId;
  final PvpUserResponse user;
  final String statusCode;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? matchId;

  PvpInviteResponse({
    required this.inviteId,
    required this.user,
    required this.statusCode,
    this.expiresAt,
    this.createdAt,
    this.matchId,
  });

  factory PvpInviteResponse.fromJson(Map<String, dynamic> json) {
    return PvpInviteResponse(
      inviteId: json['inviteId'] as String? ?? '',
      user: PvpUserResponse.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
      statusCode: json['statusCode'] as String? ?? '',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)?.toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal()
          : null,
      matchId: json['matchId'] as String?,
    );
  }
}

class PvpMatchResultResponse {
  final int mmrBefore;
  final int mmrDelta;
  final int mmrAfter;
  final bool tierChanged;
  final bool canClaimReward;
  final DateTime? claimedAt;

  PvpMatchResultResponse({
    required this.mmrBefore,
    required this.mmrDelta,
    required this.mmrAfter,
    required this.tierChanged,
    required this.canClaimReward,
    this.claimedAt,
  });

  factory PvpMatchResultResponse.fromJson(Map<String, dynamic> json) {
    return PvpMatchResultResponse(
      mmrBefore: (json['mmrBefore'] as num?)?.toInt() ?? 0,
      mmrDelta: (json['mmrDelta'] as num?)?.toInt() ?? 0,
      mmrAfter: (json['mmrAfter'] as num?)?.toInt() ?? 0,
      tierChanged: json['tierChanged'] as bool? ?? false,
      canClaimReward: json['canClaimReward'] as bool? ?? false,
      claimedAt: json['claimedAt'] != null
          ? DateTime.tryParse(json['claimedAt'] as String)?.toLocal()
          : null,
    );
  }
}

class PvpRewardClaimResponse {
  final int walletBalance;
  final int walletReward;
  final List<PvpRewardItemResponse> rewardItems;

  PvpRewardClaimResponse({
    required this.walletBalance,
    required this.walletReward,
    required this.rewardItems,
  });

  factory PvpRewardClaimResponse.fromJson(Map<String, dynamic> json) {
    final items = json['rewardItems'] as List<dynamic>? ?? [];
    return PvpRewardClaimResponse(
      walletBalance: (json['walletBalance'] as num?)?.toInt() ?? 0,
      walletReward: (json['walletReward'] as num?)?.toInt() ?? 0,
      rewardItems: items
          .map((e) => PvpRewardItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PvpRewardItemResponse {
  final String itemId;
  final int quantity;

  PvpRewardItemResponse({required this.itemId, required this.quantity});

  factory PvpRewardItemResponse.fromJson(Map<String, dynamic> json) {
    return PvpRewardItemResponse(
      itemId: json['itemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}
