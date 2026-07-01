class AchievementResponse {
  final String achievementId;
  final String title;
  final String description;
  final String? iconUrl;
  final String? metricCode;
  final int progressValue;
  final int targetValue;
  final int walletAmount;
  final List<dynamic> rewardItems;
  final bool isUnlocked;
  final bool canClaim;
  final String? unlockedAt;
  final String? claimedAt;

  AchievementResponse({
    required this.achievementId,
    required this.title,
    required this.description,
    this.iconUrl,
    this.metricCode,
    required this.progressValue,
    required this.targetValue,
    required this.walletAmount,
    required this.rewardItems,
    required this.isUnlocked,
    required this.canClaim,
    this.unlockedAt,
    this.claimedAt,
  });

  factory AchievementResponse.fromJson(Map<String, dynamic> json) {
    return AchievementResponse(
      achievementId: json['achievementId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      metricCode: json['metricCode']?.toString(),
      progressValue:
          int.tryParse(json['progressValue']?.toString() ?? '0') ?? 0,
      targetValue: int.tryParse(json['targetValue']?.toString() ?? '0') ?? 0,
      walletAmount: int.tryParse(json['walletAmount']?.toString() ?? '0') ?? 0,
      rewardItems: json['rewardItems'] is List
          ? List.from(json['rewardItems'])
          : const [],
      isUnlocked: _parseBool(json['isUnlocked']),
      canClaim: _parseBool(json['canClaim']),
      unlockedAt: json['unlockedAt']?.toString(),
      claimedAt: json['claimedAt']?.toString(),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
