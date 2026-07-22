class ClaimAchievementRewardResponse {
  final String achievementId;
  final int walletAmount;
  final List<RewardItem> rewardItems;
  final int walletBalance;
  final String claimedAt;

  ClaimAchievementRewardResponse({
    required this.achievementId,
    required this.walletAmount,
    required this.rewardItems,
    required this.walletBalance,
    required this.claimedAt,
  });

  factory ClaimAchievementRewardResponse.fromJson(Map<String, dynamic> json) {
    return ClaimAchievementRewardResponse(
      achievementId: json['achievementId']?.toString() ?? '',
      walletAmount: int.tryParse(json['walletAmount']?.toString() ?? '0') ?? 0,
      rewardItems: (json['rewardItems'] is List)
          ? (json['rewardItems'] as List)
                .map((e) => RewardItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : <RewardItem>[],
      walletBalance:
          int.tryParse(json['walletBalance']?.toString() ?? '0') ?? 0,
      claimedAt: json['claimedAt']?.toString() ?? '',
    );
  }
}

class RewardItem {
  final String itemId;
  final String itemName;
  final int quantity;

  RewardItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }
}
