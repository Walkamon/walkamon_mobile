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
