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

  PvpParticipantResponse copyWith({
    String? participantTypeCode,
    String? userId,
    String? matchPlayerId,
    String? botProfileId,
    String? displayName,
    String? avatarUrl,
    int? score,
    int? validatedSteps,
    int? distanceUnits,
    int? speedMultiplierBps,
    String? spiritAffinityCode,
    int? passiveSpeedBps,
    String? resultCode,
  }) {
    return PvpParticipantResponse(
      participantTypeCode: participantTypeCode ?? this.participantTypeCode,
      userId: userId ?? this.userId,
      matchPlayerId: matchPlayerId ?? this.matchPlayerId,
      botProfileId: botProfileId ?? this.botProfileId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      validatedSteps: validatedSteps ?? this.validatedSteps,
      distanceUnits: distanceUnits ?? this.distanceUnits,
      speedMultiplierBps: speedMultiplierBps ?? this.speedMultiplierBps,
      spiritAffinityCode: spiritAffinityCode ?? this.spiritAffinityCode,
      passiveSpeedBps: passiveSpeedBps ?? this.passiveSpeedBps,
      resultCode: resultCode ?? this.resultCode,
    );
  }
}

class PvpMatchResponse {
  final String matchId;
  final String matchTypeCode;
  final String statusCode;
  final String? sourceCode;
  final String? cancelReasonCode;
  final DateTime? serverTime;
  final DateTime? createdAt;
  final DateTime? countdownStartsAt;
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
    this.cancelReasonCode,
    this.serverTime,
    this.createdAt,
    this.countdownStartsAt,
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
    final rawCountdownStartsAt = json['countdownStartsAt'] as String?;
    final rawCountdownEndsAt = json['countdownEndsAt'] as String?;
    final rawStartedAt = json['startedAt'] as String?;
    final rawEndedAt = json['endedAt'] as String?;
    final rawSettlementEndsAt = json['settlementEndsAt'] as String?;

    final parsedServerTime = rawServerTime != null
        ? DateTime.parse(rawServerTime).toUtc()
        : null;
    final parsedCreatedAt = rawCreatedAt != null
        ? DateTime.parse(rawCreatedAt).toUtc()
        : null;
    final parsedCountdownStartsAt = rawCountdownStartsAt != null
        ? DateTime.parse(rawCountdownStartsAt).toUtc()
        : null;
    final parsedCountdownEndsAt = rawCountdownEndsAt != null
        ? DateTime.parse(rawCountdownEndsAt).toUtc()
        : null;
    final parsedStartedAt = rawStartedAt != null
        ? DateTime.parse(rawStartedAt).toUtc()
        : null;
    final parsedEndedAt = rawEndedAt != null
        ? DateTime.parse(rawEndedAt).toUtc()
        : null;
    final parsedSettlementEndsAt = rawSettlementEndsAt != null
        ? DateTime.parse(rawSettlementEndsAt).toUtc()
        : null;

    debugPrint('RAW countdownStartsAt=$rawCountdownStartsAt');
    debugPrint('PARSED countdownStartsAt=$parsedCountdownStartsAt');
    debugPrint('RAW countdownEndsAt=$rawCountdownEndsAt');
    debugPrint('PARSED countdownEndsAt=$parsedCountdownEndsAt');
    debugPrint('RAW serverTime=$rawServerTime');
    debugPrint('PARSED serverTime=$parsedServerTime');

    return PvpMatchResponse(
      matchId: json['matchId'] as String? ?? '',
      matchTypeCode: json['matchTypeCode'] as String? ?? '',
      statusCode: json['statusCode'] as String? ?? '',
      sourceCode: json['sourceCode'] as String?,
      cancelReasonCode: json['cancelReasonCode'] as String?,
      serverTime: parsedServerTime,
      createdAt: parsedCreatedAt,
      countdownStartsAt: parsedCountdownStartsAt,
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

/// UC-70 paginated sprint match history.
class PvpMatchHistoryPage {
  final int page;
  final int pageSize;
  final int total;
  final List<PvpMatchResponse> items;

  PvpMatchHistoryPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  bool get hasMore => page * pageSize < total;

  factory PvpMatchHistoryPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return PvpMatchHistoryPage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      items: items
          .map((e) => PvpMatchResponse.fromJson(e as Map<String, dynamic>))
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

  /// Presence của user trong object `user` (người kia, không phải user đang login).
  /// true = đang có SignalR connection.
  final bool otherUserIsOnline;

  /// Trạng thái PvP của người kia: 'available' | 'busy' | 'offline'.
  final String otherUserPvpAvailabilityCode;

  PvpInviteResponse({
    required this.inviteId,
    required this.user,
    required this.statusCode,
    this.expiresAt,
    this.createdAt,
    this.matchId,
    this.otherUserIsOnline = false,
    this.otherUserPvpAvailabilityCode = 'offline',
  });

  /// Có thể chấp nhận invite này: người kia online & available & invite chưa hết hạn.
  bool get canAccept =>
      statusCode == 'pending' &&
      otherUserIsOnline &&
      otherUserPvpAvailabilityCode == 'available' &&
      (expiresAt == null || DateTime.now().isBefore(expiresAt!));

  /// Tạo bản sao với presence mới từ SignalR presence.changed
  PvpInviteResponse copyWithPresence({
    required bool isOnline,
    required String pvpAvailabilityCode,
  }) {
    return PvpInviteResponse(
      inviteId: inviteId,
      user: user,
      statusCode: statusCode,
      expiresAt: expiresAt,
      createdAt: createdAt,
      matchId: matchId,
      otherUserIsOnline: isOnline,
      otherUserPvpAvailabilityCode: pvpAvailabilityCode,
    );
  }

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
      otherUserIsOnline: json['otherUserIsOnline'] == true,
      otherUserPvpAvailabilityCode:
          json['otherUserPvpAvailabilityCode'] as String? ?? 'offline',
    );
  }
}

class PvpInvitePage {
  final int page;
  final int pageSize;
  final int total;
  final List<PvpInviteResponse> items;

  PvpInvitePage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory PvpInvitePage.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return PvpInvitePage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      items: itemsList
          .map((e) => PvpInviteResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PvpRankTierResponse {
  final String tierCode;
  final String displayName;
  final int minMmr;
  final String? assetKey;
  final String? colorHex;

  PvpRankTierResponse({
    required this.tierCode,
    required this.displayName,
    required this.minMmr,
    this.assetKey,
    this.colorHex,
  });

  factory PvpRankTierResponse.fromJson(Map<String, dynamic> json) {
    return PvpRankTierResponse(
      tierCode: json['tierCode'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      minMmr: (json['minMmr'] as num?)?.toInt() ?? 0,
      assetKey: json['assetKey'] as String?,
      colorHex: json['colorHex'] as String?,
    );
  }

  /// Converts API `Assets/Mobile/...` keys to Flutter asset paths.
  String? get flutterAssetPath {
    final key = assetKey?.trim();
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('assets/')) return key;
    if (key.startsWith('Assets/')) {
      return 'assets/${key.substring('Assets/'.length)}';
    }
    return key;
  }
}

class PvpMatchResultResponse {
  /// Full match payload (same fields as GET match).
  final PvpMatchResponse match;
  final int mmrBefore;
  final int mmrDelta;
  final int mmrAfter;
  final PvpRankTierResponse? rankBefore;
  final PvpRankTierResponse? rankAfter;
  final bool tierChanged;
  final bool canClaimReward;
  final DateTime? claimedAt;

  PvpMatchResultResponse({
    required this.match,
    required this.mmrBefore,
    required this.mmrDelta,
    required this.mmrAfter,
    this.rankBefore,
    this.rankAfter,
    required this.tierChanged,
    required this.canClaimReward,
    this.claimedAt,
  });

  String get matchId => match.matchId;
  String get matchTypeCode => match.matchTypeCode;
  String get statusCode => match.statusCode;
  List<PvpParticipantResponse> get participants => match.participants;

  /// Ranked matches change MMR; friendly/event keep `mmrDelta = 0`.
  bool get isRanked => matchTypeCode.toLowerCase() == 'ranked';

  PvpParticipantResponse? participantForUser(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      for (final p in participants) {
        if (p.userId == userId) return p;
      }
      return null;
    }
    for (final p in participants) {
      final id = p.userId;
      if (id != null && id.isNotEmpty) return p;
    }
    return null;
  }

  String? resultCodeForUser(String? userId) =>
      participantForUser(userId)?.resultCode?.toLowerCase();

  factory PvpMatchResultResponse.fromJson(Map<String, dynamic> json) {
    return PvpMatchResultResponse(
      match: PvpMatchResponse.fromJson(json),
      mmrBefore: (json['mmrBefore'] as num?)?.toInt() ?? 0,
      mmrDelta: (json['mmrDelta'] as num?)?.toInt() ?? 0,
      mmrAfter: (json['mmrAfter'] as num?)?.toInt() ?? 0,
      rankBefore: _parseRankTier(json['rankBefore']),
      rankAfter: _parseRankTier(json['rankAfter']),
      tierChanged: json['tierChanged'] == true,
      canClaimReward: json['canClaimReward'] == true,
      claimedAt: json['claimedAt'] == null
          ? null
          : DateTime.tryParse(json['claimedAt'].toString())?.toLocal(),
    );
  }

  static PvpRankTierResponse? _parseRankTier(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final map = <String, dynamic>{};
    raw.forEach((key, value) {
      map[key.toString()] = value;
    });
    if (map.isEmpty) return null;
    final tierCode = map['tierCode']?.toString();
    if (tierCode == null || tierCode.isEmpty) return null;
    return PvpRankTierResponse.fromJson(map);
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
