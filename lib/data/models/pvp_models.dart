
class PvpParticipantResponse {
  final String participantTypeCode;
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
  final int? score;
  final int? distanceUnits;
  final String? spiritAffinityCode;

  PvpParticipantResponse({
    required this.participantTypeCode,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.score,
    this.distanceUnits,
    this.spiritAffinityCode,
  });

  factory PvpParticipantResponse.fromJson(Map<String, dynamic> json) {
    return PvpParticipantResponse(
      participantTypeCode: json['participantTypeCode'] as String? ?? '',
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num?)?.toInt(),
      distanceUnits: (json['distanceUnits'] as num?)?.toInt(),
      spiritAffinityCode: json['spiritAffinityCode'] as String?,
    );
  }
}

class PvpMatchResponse {
  final String matchId;
  final String matchTypeCode;
  final String statusCode;
  final DateTime? serverTime;
  final DateTime? createdAt;
  final List<PvpParticipantResponse> participants;

  PvpMatchResponse({
    required this.matchId,
    required this.matchTypeCode,
    required this.statusCode,
    this.serverTime,
    this.createdAt,
    required this.participants,
  });

  factory PvpMatchResponse.fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List<dynamic>? ?? [];
    return PvpMatchResponse(
      matchId: json['matchId'] as String? ?? '',
      matchTypeCode: json['matchTypeCode'] as String? ?? '',
      statusCode: json['statusCode'] as String? ?? '',
      serverTime: json['serverTime'] != null
          ? DateTime.tryParse(json['serverTime'] as String)?.toLocal()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal()
          : null,
      participants: participantsList
          .map((e) => PvpParticipantResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      user: PvpUserResponse.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
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
