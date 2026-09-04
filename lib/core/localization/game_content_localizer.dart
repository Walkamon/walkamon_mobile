import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Localizes system-owned mission, challenge and achievement content.
///
/// The API still returns its legacy display text for backward compatibility,
/// but stable metric codes are the source of truth for supported languages.
abstract final class GameContentLocalizer {
  static String questTitle(
    BuildContext context, {
    required String metricCode,
    required int targetValue,
    required String fallback,
  }) {
    final l10n = AppLocalizations.of(context);
    return switch (_normalize(metricCode)) {
      'steps' => l10n.systemQuestStepsTitle(targetValue),
      'feed_pet' => l10n.systemQuestFeedTitle(targetValue),
      'mission_completed' => l10n.systemQuestMissionTitle(targetValue),
      'wallet_earned' => l10n.systemQuestWalletTitle(targetValue),
      'pet_level' => l10n.systemQuestPetLevelTitle(targetValue),
      _ =>
        _looksVietnamese(fallback)
            ? l10n.systemQuestUnknownTitle
            : _nonEmpty(fallback, l10n.systemQuestUnknownTitle),
    };
  }

  static String questDescription(
    BuildContext context, {
    required String metricCode,
    required int targetValue,
    required String fallback,
  }) {
    final l10n = AppLocalizations.of(context);
    return switch (_normalize(metricCode)) {
      'steps' => l10n.systemQuestStepsDescription(targetValue),
      'feed_pet' => l10n.systemQuestFeedDescription(targetValue),
      'mission_completed' => l10n.systemQuestMissionDescription(targetValue),
      'wallet_earned' => l10n.systemQuestWalletDescription(targetValue),
      'pet_level' => l10n.systemQuestPetLevelDescription(targetValue),
      _ =>
        _looksVietnamese(fallback)
            ? l10n.missionsDefaultDescription
            : _nonEmpty(fallback, l10n.missionsDefaultDescription),
    };
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('-', '_');

  static String _nonEmpty(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();

  static bool _looksVietnamese(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (RegExp(
      r'[ăâđêôơưàáạảãèéẹẻẽìíịỉĩòóọỏõùúụủũỳýỵỷỹ]',
    ).hasMatch(normalized)) {
      return true;
    }
    return RegExp(
      r'\b(nhiem vu|thu thach|hoan thanh|cham soc|buoc|di bo|nhan thuong)\b',
    ).hasMatch(normalized);
  }
}
