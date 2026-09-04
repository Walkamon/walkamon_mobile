import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../network/api_response.dart';
import '../network/app_failure.dart';

class TranslationResolver {
  const TranslationResolver._();

  static String resolveResponse(
    BuildContext context,
    ApiResponse<dynamic> response,
  ) => resolveFailure(context, response.failure);

  static String resolveError(BuildContext context, Object error) {
    if (error is AppFailure) return resolveFailure(context, error);
    if (kDebugMode) debugPrint('Unexpected client error: $error');
    return AppLocalizations.of(context).apiErrorUnexpectedResponse;
  }

  static String resolveFailure(BuildContext context, AppFailure failure) {
    final l10n = AppLocalizations.of(context);
    if (kDebugMode) {
      debugPrint(
        'API failure code=${failure.code} status=${failure.status} '
        'traceId=${failure.traceId ?? '-'}',
      );
    }

    final translated = switch (failure.code) {
      'BAD_REQUEST' => l10n.apiErrorBadRequest,
      'UNAUTHORIZED' => l10n.apiErrorUnauthorized,
      'FORBIDDEN' => l10n.apiErrorForbidden,
      'NOT_FOUND' => l10n.apiErrorNotFound,
      'CONFLICT' || 'CONCURRENCY_CONFLICT' => l10n.apiErrorConflict,
      'TOO_MANY_REQUESTS' => l10n.apiErrorTooManyRequests,
      'INTERNAL_ERROR' => l10n.apiErrorInternal,
      'NETWORK_UNAVAILABLE' => l10n.apiErrorNetworkUnavailable,
      'REQUEST_TIMEOUT' => l10n.apiErrorRequestTimeout,
      'UNEXPECTED_RESPONSE' => l10n.apiErrorUnexpectedResponse,
      'VALIDATION_FAILED' => l10n.apiErrorValidationFailed,
      'AUTH_ACCOUNT_NOT_ACTIVE' => l10n.apiErrorAccountNotActive,
      'AUTH_EMAIL_ALREADY_EXISTS' => l10n.apiErrorAuthEmailExists,
      'AUTH_USERNAME_ALREADY_EXISTS' => l10n.apiErrorAuthUsernameExists,
      'AUTH_IDENTITY_ALREADY_EXISTS' => l10n.apiErrorAuthIdentityExists,
      'AUTH_OTP_REQUEST_INVALID' => l10n.apiErrorAuthOtpRequestInvalid,
      'AUTH_OTP_EXPIRED' => l10n.apiErrorAuthOtpExpired,
      'AUTH_OTP_INVALID' => l10n.apiErrorAuthOtpInvalid,
      'AUTH_RESET_TICKET_INVALID' => l10n.apiErrorAuthResetInvalid,
      'AUTH_ACCOUNT_LOCKED' => l10n.apiErrorAuthAccountLocked,
      'AUTH_CURRENT_PASSWORD_INVALID' => l10n.apiErrorAuthCurrentPassword,
      'AUTH_GOOGLE_TOKEN_INVALID' ||
      'AUTH_GOOGLE_LOGIN_INVALID' => l10n.apiErrorAuthGoogleInvalid,
      'AUTH_GOOGLE_EMAIL_UNVERIFIED' => l10n.apiErrorAuthGoogleUnverified,
      'USER_NOT_FOUND' => l10n.apiErrorUserNotFound,
      'PROFILE_NOT_FOUND' => l10n.apiErrorProfileNotFound,
      'PET_STARTER_NOT_FOUND' ||
      'PET_NOT_FOUND' ||
      'PET_FRIEND_NOT_FOUND' => l10n.apiErrorPetNotFound,
      'PET_ALREADY_EXISTS' => l10n.apiErrorPetAlreadyExists,
      'PET_BOND_FULL' => l10n.apiErrorPetBondFull,
      'PET_TAP_LIMIT_REACHED' => l10n.apiErrorPetTapLimit,
      'PET_LIFE_FORCE_FULL' => l10n.apiErrorPetLifeForceFull,
      'PET_FEED_LIMIT_REACHED' => l10n.apiErrorPetFeedLimit,
      'PET_FINAL_STAGE' => l10n.apiErrorPetFinalStage,
      'MISSION_NOT_FOUND' => l10n.apiErrorMissionNotFound,
      'MISSION_NOT_COMPLETED' => l10n.apiErrorMissionNotCompleted,
      'MISSION_REWARD_ALREADY_CLAIMED' => l10n.apiErrorRewardAlreadyClaimed,
      'MISSION_CANCELLED' => l10n.apiErrorMissionCancelled,
      'ACHIEVEMENT_NOT_FOUND' => l10n.apiErrorAchievementNotFound,
      'ACHIEVEMENT_NOT_UNLOCKED' ||
      'ACHIEVEMENT_NOT_COMPLETED' => l10n.apiErrorAchievementNotCompleted,
      'ACHIEVEMENT_REWARD_ALREADY_CLAIMED' ||
      'DAILY_REWARD_ALREADY_CLAIMED' => l10n.apiErrorRewardAlreadyClaimed,
      'SHOP_QUANTITY_INVALID' => l10n.apiErrorShopQuantity,
      'WALLET_INSUFFICIENT_BALANCE' => l10n.apiErrorWalletBalance,
      'SHOP_ITEM_NOT_FOUND' ||
      'INVENTORY_ITEM_NOT_FOUND' => l10n.apiErrorItemNotFound,
      'FRIEND_REQUEST_SELF' => l10n.apiErrorFriendSelf,
      'FRIEND_REQUEST_ALREADY_SENT' => l10n.friendsRequestAlreadySent,
      'FRIEND_ALREADY_EXISTS' => l10n.friendsAlreadyFriend,
      'FRIEND_REQUEST_NOT_FOUND' ||
      'FRIENDSHIP_NOT_FOUND' => l10n.friendsPlayerNotFound,
      'NOTIFICATION_NOT_FOUND' => l10n.apiErrorNotificationNotFound,
      'FEEDBACK_COOLDOWN' => l10n.apiErrorFeedbackCooldown(
        _intParam(failure.params, 'retryAfterHours', fallback: 24),
      ),
      'PVP_LOADOUT_INVALID_SLOT' => l10n.apiErrorPvpInvalidSlot,
      'PVP_LOADOUT_DUPLICATE_ITEM' => l10n.apiErrorPvpDuplicateItem,
      'PVP_LOADOUT_ITEM_INVALID' => l10n.apiErrorPvpInvalidItem,
      'PVP_LOADOUT_ITEM_NOT_OWNED' => l10n.apiErrorPvpItemNotOwned,
      'PVP_LOADOUT_LOCKED' => l10n.apiErrorPvpLoadoutLocked,
      'PVP_ITEM_ACTION_INVALID' => l10n.apiErrorPvpActionInvalid,
      'PVP_MATCH_NOT_FOUND' => l10n.apiErrorPvpMatchNotFound,
      'PVP_MATCH_NOT_PARTICIPANT' => l10n.apiErrorPvpNotParticipant,
      'PVP_MATCH_NOT_RUNNING' => l10n.apiErrorPvpMatchNotRunning,
      'PVP_ITEM_REQUIRES_ACTIVE_MATCH' => l10n.apiErrorPvpMatchNotRunning,
      'PVP_ITEM_SLOT_NOT_FOUND' => l10n.apiErrorPvpSlotNotFound,
      'PVP_ITEM_ALREADY_USED' => l10n.apiErrorPvpItemAlreadyUsed,
      'PVP_ITEM_UNAVAILABLE' => l10n.apiErrorPvpItemUnavailable,
      'PVP_EFFECT_CONFLICT' => l10n.apiErrorPvpEffectConflict,
      'PVP_BOT_UNAVAILABLE' => l10n.apiErrorPvpBotUnavailable,
      'PVP_INSUFFICIENT_ENERGY' => l10n.apiErrorPvpInsufficientEnergy(
        _intParam(failure.params, 'requiredEnergy', fallback: 15),
      ),
      'PVP_READY_TIMEOUT' => l10n.apiErrorPvpReadyTimeout,
      'PVP_MATCHMAKING_FAILED' => l10n.apiErrorPvpMatchmakingFailed,
      'UNSUPPORTED_ITEM_EFFECT' => l10n.apiErrorPvpInvalidItem,
      'PVP_ITEM_NOT_IN_SNAPSHOT' => l10n.apiErrorPvpSlotNotFound,
      'TRANSLATION_REQUIRED' || 'TRANSLATION_UNAVAILABLE' =>
          l10n.apiErrorUnexpectedResponse,
      _ => null,
    };
    if (translated != null) return translated;

    final fallback = failure.fallbackMessage.trim();
    if (fallback.isNotEmpty &&
        fallback.toLowerCase() != 'internal server error') {
      return fallback;
    }
    return l10n.apiErrorUnexpectedResponse;
  }

  static int _intParam(
    Map<String, dynamic> params,
    String key, {
    required int fallback,
  }) {
    final value = params[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
