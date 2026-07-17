class DailyLoginCalendarData {
  final String serverDate;
  final bool canClaimToday;
  final String? lastClaimDate;
  final int currentDay;
  final List<DailyLoginRewardModel> rewards;

  DailyLoginCalendarData({
    required this.serverDate,
    required this.canClaimToday,
    this.lastClaimDate,
    required this.currentDay,
    required this.rewards,
  });

  factory DailyLoginCalendarData.fromJson(Map<String, dynamic> json) {
    return DailyLoginCalendarData(
      serverDate: json['serverDate'] ?? '',
      canClaimToday: json['canClaimToday'] ?? false,
      lastClaimDate: json['lastClaimDate'],
      currentDay: json['currentDay'] ?? 1,
      rewards:
          (json['rewards'] as List?)
              ?.map((e) => DailyLoginRewardModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DailyLoginRewardModel {
  final int day;
  final int reward;
  final String status;

  DailyLoginRewardModel({
    required this.day,
    required this.reward,
    required this.status,
  });

  factory DailyLoginRewardModel.fromJson(Map<String, dynamic> json) {
    return DailyLoginRewardModel(
      day: json['day'] ?? 0,
      reward: json['reward'] ?? 0,
      status: json['status'] ?? 'locked',
    );
  }
}

class ClaimDailyRewardData {
  final String claimDate;
  final int claimedDay;
  final int reward;
  final int balance;
  final int nextDay;

  ClaimDailyRewardData({
    required this.claimDate,
    required this.claimedDay,
    required this.reward,
    required this.balance,
    required this.nextDay,
  });

  factory ClaimDailyRewardData.fromJson(Map<String, dynamic> json) {
    return ClaimDailyRewardData(
      claimDate: json['claimDate'] ?? '',
      claimedDay: json['claimedDay'] ?? 0,
      reward: json['reward'] ?? 0,
      balance: json['balance'] ?? 0,
      nextDay: json['nextDay'] ?? 0,
    );
  }
}
