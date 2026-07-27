import 'package:flutter/foundation.dart';

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
  final int? countdownSecondsRemaining;
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
    this.countdownSecondsRemaining,
    this.startedAt,
    this.endedAt,
    this.settlementEndsAt,
    this.lastEventSequence,
    required this.participants,
  });

  factory PvpMatchResponse.fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List<dynamic>? ?? [];
    final rawServerTime = json['serverTime'] as String?;
    final rawCreatedAt = json['createdAt'] as String?;
    final rawCountdownEndsAt = json['countdownEndsAt'] as String?;
    final rawStartedAt = json['startedAt'] as String?;
    final rawEndedAt = json['endedAt'] as String?;
    final rawSettlementEndsAt = json['settlementEndsAt'] as String?;

    final parsedServerTime = rawServerTime != null
        ? DateTime.parse(rawServerTime)
        : null;
    final parsedCreatedAt = rawCreatedAt != null
        ? DateTime.parse(rawCreatedAt)
        : null;
    final parsedCountdownEndsAt = rawCountdownEndsAt != null
        ? DateTime.parse(rawCountdownEndsAt)
        : null;
    final parsedStartedAt = rawStartedAt != null
        ? DateTime.parse(rawStartedAt)
        : null;
    final parsedEndedAt = rawEndedAt != null
        ? DateTime.parse(rawEndedAt)
        : null;
    final parsedSettlementEndsAt = rawSettlementEndsAt != null
        ? DateTime.parse(rawSettlementEndsAt)
        : null;

    debugPrint('RAW countdownEndsAt=$rawCountdownEndsAt');
    debugPrint('PARSED countdownEndsAt=$parsedCountdownEndsAt');
    debugPrint('RAW serverTime=$rawServerTime');
    debugPrint('PARSED serverTime=$parsedServerTime');

    return PvpMatchResponse(
      matchId: json['matchId'] as String? ?? '',
      matchTypeCode: json['matchTypeCode'] as String? ?? '',
      statusCode: json['statusCode'] as String? ?? '',
      sourceCode: json['sourceCode'] as String?,
      serverTime: parsedServerTime,
      createdAt: parsedCreatedAt,
      countdownEndsAt: parsedCountdownEndsAt,
      countdownSecondsRemaining: json['countdownSecondsRemaining'] is int
          ? json['countdownSecondsRemaining'] as int
          : int.tryParse('${json['countdownSecondsRemaining']}'),
      startedAt: parsedStartedAt,
      endedAt: parsedEndedAt,
      settlementEndsAt: parsedSettlementEndsAt,
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
    DateTime? parseDateTime(String? value) =>
        value != null ? DateTime.parse(value) : null;

    return PvpMatchmakingStatusResponse(
      activityType: json['activityType'] as String? ?? 'idle',
      statusCode: json['statusCode'] as String? ?? 'idle',
      matchId: json['matchId'] as String?,
      queuedAt: parseDateTime(json['queuedAt'] as String?),
      botFallbackAt: parseDateTime(json['botFallbackAt'] as String?),
      serverTime: parseDateTime(json['serverTime'] as String?),
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
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
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
