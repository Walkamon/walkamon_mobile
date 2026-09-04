import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Resolves system-owned notification labels from stable codes.
///
/// Names supplied by a player/admin are deliberately kept as fallback text;
/// they are content, not a translatable system key.  This also keeps legacy
/// notifications readable while newer payloads carry `contentCode`/`params`.
abstract final class NotificationContentResolver {
  static String title(
    BuildContext context, {
    String? typeCode,
    String? contentCode,
    Map<String, dynamic> params = const <String, dynamic>{},
    String fallback = '',
  }) {
    final code = (contentCode?.trim().isNotEmpty == true
            ? contentCode
            : typeCode)
        ?.trim()
        .toLowerCase()
        .replaceAll('-', '_');
    final l10n = AppLocalizations.of(context);
    final localized = switch (code) {
      'daily_reward' => l10n.notificationsTypeDailyReward,
      'daily_step_goal_reminder' => l10n.notificationsTypeDailyStepGoalReminder,
      'streak_reward' => l10n.notificationsTypeStreakReward,
      'mission_complete' => l10n.notificationsTypeMissionComplete,
      'achievement_complete' => l10n.notificationsTypeAchievementComplete,
      'challenge_invite' => l10n.notificationsTypeChallengeInvite,
      'pvp_invite' => l10n.notificationsTypePvpInvite,
      'friend_request' => l10n.notificationsTypeFriendRequest,
      'friend_accepted' => l10n.notificationsTypeFriendAccepted,
      'friend_removed' => l10n.notificationsTypeFriendRemoved,
      'spirit_hungry' => l10n.notificationsTypeSpiritHungry,
      'spirit_ready_evolution' => l10n.notificationsTypeSpiritReadyEvolution,
      'spirit_energy_full' => l10n.notificationsTypeSpiritEnergyFull,
      'spirit_bond_low' => l10n.notificationsTypeSpiritBondLow,
      'spirit_level_up' => l10n.notificationsTypeSpiritLevelUp,
      'item_purchased' => l10n.notificationsTypeItemPurchased,
      'pvp_result' => l10n.notificationsTypePvpResult,
      'maintenance' => l10n.notificationsTypeMaintenance,
      'patch_notes' => l10n.notificationsTypePatchNotes,
      'news' => l10n.notificationsTypeNews,
      'event' => l10n.notificationsTypeEvent,
      'compensation' => l10n.notificationsTypeCompensation,
      'server_announcement' => l10n.notificationsTypeServerAnnouncement,
      _ => null,
    };
    if (localized != null) return localized;
    return fallback.trim();
  }
}
