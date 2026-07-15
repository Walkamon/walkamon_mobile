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
      rewards: (json['rewards'] as List?)
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
