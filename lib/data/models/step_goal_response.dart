class GoalProgressResponse {
  GoalProgressResponse({
    required this.targetSteps,
    required this.currentSteps,
    required this.remainingSteps,
    required this.progressPercent,
    required this.completed,
  });

  final int targetSteps;
  final int currentSteps;
  final int remainingSteps;
  final double progressPercent;
  final bool completed;

  factory GoalProgressResponse.fromJson(Map<String, dynamic> json) {
    return GoalProgressResponse(
      targetSteps: int.tryParse(json['targetSteps']?.toString() ?? '0') ?? 0,
      currentSteps: int.tryParse(json['currentSteps']?.toString() ?? '0') ?? 0,
      remainingSteps:
          int.tryParse(json['remainingSteps']?.toString() ?? '0') ?? 0,
      progressPercent:
          double.tryParse(json['progressPercent']?.toString() ?? '0') ?? 0,
      completed: json['completed'] == true,
    );
  }
}

class CurrentStreakResponse {
  CurrentStreakResponse({required this.currentStreak});

  final int currentStreak;

  factory CurrentStreakResponse.fromJson(Map<String, dynamic> json) {
    return CurrentStreakResponse(
      currentStreak:
          int.tryParse(json['currentStreak']?.toString() ?? '0') ?? 0,
    );
  }
}

class LongestStreakResponse {
  LongestStreakResponse({required this.longestStreak});

  final int longestStreak;

  factory LongestStreakResponse.fromJson(Map<String, dynamic> json) {
    return LongestStreakResponse(
      longestStreak:
          int.tryParse(json['longestStreak']?.toString() ?? '0') ?? 0,
    );
  }
}

class StepGoalClaimRewardResponse {
  StepGoalClaimRewardResponse({
    required this.streak,
    required this.reward,
    required this.balance,
    required this.claimDate,
  });

  final int streak;
  final int reward;
  final int balance;
  final String claimDate;

  factory StepGoalClaimRewardResponse.fromJson(Map<String, dynamic> json) {
    return StepGoalClaimRewardResponse(
      streak: int.tryParse(json['streak']?.toString() ?? '0') ?? 0,
      reward: int.tryParse(json['reward']?.toString() ?? '0') ?? 0,
      balance: int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      claimDate: json['claimDate']?.toString() ?? '',
    );
  }
}
