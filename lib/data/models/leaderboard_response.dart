class LeaderboardResponse {
  final String type;
  final String fromDate;
  final String toDate;
  final int myRank;
  final List<LeaderboardUser> leaderboard;

  LeaderboardResponse({
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.myRank,
    required this.leaderboard,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      type: json['type']?.toString() ?? '',
      fromDate: json['fromDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? '',
      myRank: int.tryParse(json['myRank']?.toString() ?? '') ?? 0,
      leaderboard: (json['leaderboard'] as List<dynamic>? ?? [])
          .map((item) => LeaderboardUser.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LeaderboardUser {
  final int rank;
  final String userId;
  final String? username;
  final String? avatar;
  final int stepCount;
  final bool isCurrentUser;

  LeaderboardUser({
    required this.rank,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.stepCount,
    required this.isCurrentUser,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      rank: int.tryParse(json['rank']?.toString() ?? '') ?? 0,
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString(),
      stepCount: int.tryParse(json['stepCount']?.toString() ?? '') ?? 0,
      isCurrentUser: json['isCurrentUser'] == true,
    );
  }
}

class PetLeaderboardResponse {
  final int? myRank;
  final List<PetLeaderboardUser> leaderboard;

  const PetLeaderboardResponse({
    required this.myRank,
    required this.leaderboard,
  });

  factory PetLeaderboardResponse.fromJson(dynamic json) {
    final object = json is Map
        ? Map<String, dynamic>.from(json)
        : <String, dynamic>{};
    final rawLeaderboard = json is List
        ? json
        : (object['leaderboard'] ?? object['Leaderboard']);
    return PetLeaderboardResponse(
      myRank: _readOptionalInt(object, 'myRank', 'MyRank'),
      leaderboard: rawLeaderboard is List
          ? rawLeaderboard
                .whereType<Map>()
                .map(
                  (item) => PetLeaderboardUser.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <PetLeaderboardUser>[],
    );
  }
}

class PetLeaderboardUser {
  final int rank;
  final String userId;
  final String? username;
  final int level;
  final bool isCurrentUser;

  const PetLeaderboardUser({
    required this.rank,
    required this.userId,
    required this.username,
    required this.level,
    required this.isCurrentUser,
  });

  factory PetLeaderboardUser.fromJson(Map<String, dynamic> json) {
    return PetLeaderboardUser(
      rank: _readInt(json, 'rank', 'Rank'),
      userId: _readString(json, 'userId', 'UserId'),
      username: _readNullableString(
        json,
        'username',
        'Username',
        fallbackKey: 'userName',
        fallbackPascalKey: 'UserName',
      ),
      level: _readInt(json, 'level', 'Level'),
      isCurrentUser: _readBool(json, 'isCurrentUser', 'IsCurrentUser'),
    );
  }
}

int _readInt(Map<String, dynamic> json, String camelKey, String pascalKey) {
  return int.tryParse((json[camelKey] ?? json[pascalKey])?.toString() ?? '') ??
      0;
}

String _readString(Map<String, dynamic> json, String camelKey, String pascalKey) {
  return (json[camelKey] ?? json[pascalKey])?.toString() ?? '';
}

String? _readNullableString(
  Map<String, dynamic> json,
  String camelKey,
  String pascalKey,
  {
    String? fallbackKey,
    String? fallbackPascalKey,
  }
) {
  final value =
      json[camelKey] ??
      json[pascalKey] ??
      (fallbackKey == null ? null : json[fallbackKey]) ??
      (fallbackPascalKey == null ? null : json[fallbackPascalKey]);
  return value?.toString();
}

int? _readOptionalInt(
  Map<String, dynamic> json,
  String camelKey,
  String pascalKey,
) {
  final value = json[camelKey] ?? json[pascalKey];
  return value == null ? null : int.tryParse(value.toString());
}

bool _readBool(Map<String, dynamic> json, String camelKey, String pascalKey) {
  final value = json[camelKey] ?? json[pascalKey];
  return value == true || value?.toString().toLowerCase() == 'true';
}
