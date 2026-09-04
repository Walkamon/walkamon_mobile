import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/common/game_button_label.dart';
import '../../../../widgets/pet_runtime/pet_runtime_preview.dart';
import '../../../../data/models/pvp_models.dart';
import '../../../../providers/pvp_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/common/app_icon.dart';
import '../pvp_asset_resolver.dart';
import 'pvp_frame_animation.dart';

const _opponentPlaceholder = '\u{FFFC}';

TextSpan _opponentMessageSpan({
  required String message,
  required String opponentName,
  required TextStyle? style,
}) {
  final opponentIndex = message.indexOf(_opponentPlaceholder);
  if (opponentIndex < 0) {
    return TextSpan(text: message, style: style);
  }

  return TextSpan(
    style: style,
    children: [
      TextSpan(text: message.substring(0, opponentIndex)),
      TextSpan(
        text: opponentName,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
      TextSpan(
        text: message.substring(opponentIndex + _opponentPlaceholder.length),
      ),
    ],
  );
}

class PvPMatchingOverlay extends StatelessWidget {
  const PvPMatchingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                l10n.pvpSearchingOpponent,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One authoritative overlay for queueing, match reveal and the server
/// countdown.  Keeping these phases in one card prevents the old searching
/// dialog and success dialog from being stacked or racing a local timer.
class PvpMatchTransitionOverlay extends StatelessWidget {
  const PvpMatchTransitionOverlay({
    super.key,
    required this.state,
    required this.opponentName,
    required this.countdown,
    this.isPractice = false,
    this.onCancel,
  });

  final PvpMatchmakingState state;
  final String opponentName;
  final int countdown;
  final bool isPractice;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final matched = opponentName.trim().isNotEmpty &&
        state == PvpMatchmakingState.countdown;
    final title = matched ? l10n.pvpMatchSuccess : l10n.pvpSearchingOpponent;
    final subtitle = matched
        ? l10n.pvpPrepareForMatch
        : l10n.pvpSearchingOpponent;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x8A0F1A12),
        child: Center(
          child: SafeArea(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              decoration: BoxDecoration(
                color: AppColors.authCard,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.woodDeep, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    matched ? Icons.sports_kabaddi_rounded : Icons.search_rounded,
                    color: AppColors.leaf,
                    size: 38,
                  ),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.woodDeep, fontSize: 20, fontWeight: FontWeight.w900)),
                  if (isPractice) ...[
                    const SizedBox(height: 5),
                    Text(l10n.pvpPracticeRace, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w800)),
                  ],
                  if (matched) ...[
                    const SizedBox(height: 4),
                    Text(opponentName, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkBrown, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(countdown > 0 ? '$countdown' : subtitle, style: TextStyle(color: AppColors.coral, fontSize: countdown > 0 ? 42 : 14, fontWeight: FontWeight.w900)),
                  ] else ...[
                    const SizedBox(height: 12),
                    const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.leaf)),
                  ],
                  if (onCancel != null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton(onPressed: onCancel, child: Text(l10n.pvpCancelRequest)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PvPWaitingFriendOverlay extends StatelessWidget {
  final String opponentName;
  final VoidCallback onCancel;

  const PvPWaitingFriendOverlay({
    super.key,
    required this.opponentName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                l10n.pvpInviteSent,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                text: _opponentMessageSpan(
                  message: l10n.pvpWaitingForFriend(_opponentPlaceholder),
                  opponentName: opponentName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onCancel,
                child: Text(l10n.pvpCancelRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PvPRoomCountdownOverlay extends StatelessWidget {
  final String opponentName;
  final int countdown;

  const PvPRoomCountdownOverlay({
    super.key,
    required this.opponentName,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  Icons.sports_kabaddi,
                  size: 48,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.pvpConnected,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: _opponentMessageSpan(
                  message: l10n.pvpRaceAgainst(_opponentPlaceholder),
                  opponentName: opponentName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                countdown > 0 ? materialL10n.formatDecimal(countdown) : '',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pvpPrepareForMatch,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PvPMatchSuccessOverlay extends StatelessWidget {
  const PvPMatchSuccessOverlay({
    super.key,
    required this.myAffinityCode,
    required this.opponentAffinityCode,
    required this.myStageNo,
    this.opponentStageNo = 0,
  });

  final String myAffinityCode;
  final String opponentAffinityCode;
  final int myStageNo;
  final int opponentStageNo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: const Color(0xA60F1A12),
      alignment: Alignment.center,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameButtonLabel(
                  l10n.pvpMatchSuccess,
                  fontSize: 22,
                  color: AppColors.buttonText,
                  outlineColor: AppColors.woodDeep,
                  outlineWidth: 4,
                ),
                const SizedBox(height: 14),
                Container(
                  height: 178,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.authCard.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.woodDeep.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PvpVersusPetSlot(
                          affinityCode: myAffinityCode,
                          stageNo: myStageNo,
                          isLeft: true,
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.leafLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.woodDeep.withValues(alpha: 0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GameButtonLabel(
                          'VS',
                          fontSize: 22,
                          color: AppColors.coral,
                          outlineColor: AppColors.woodDeep,
                          outlineWidth: 3,
                        ),
                      ),
                      Expanded(
                        child: _PvpVersusPetSlot(
                          affinityCode: opponentAffinityCode,
                          stageNo: opponentStageNo,
                          isLeft: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GameButtonLabel(
                  l10n.pvpEnteringRace,
                  fontSize: 15,
                  color: AppColors.buttonText,
                  outlineColor: AppColors.woodDeep,
                  outlineWidth: 3,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PvpVersusPetSlot extends StatelessWidget {
  const _PvpVersusPetSlot({
    required this.affinityCode,
    required this.stageNo,
    required this.isLeft,
  });

  final String affinityCode;
  final int stageNo;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide.clamp(92.0, 150.0);
        return Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: PetRuntimePreview(
            affinityCode: affinityCode,
            stageNo: stageNo,
            animationType: 'idle',
            compact: true,
            height: size,
          ),
        );
      },
    );
  }
}

class PvPFinishedOverlay extends StatelessWidget {
  final PvpMatchResultResponse? result;
  final bool isLoading;
  final String? currentUserId;
  final String? forcedResultCode;
  final String opponentName;
  final VoidCallback onContinue;
  final Future<void> Function()? onClaimReward;
  final bool isClaiming;
  final PvpRewardClaimResponse? claimResponse;

  const PvPFinishedOverlay({
    super.key,
    required this.result,
    required this.isLoading,
    required this.currentUserId,
    this.forcedResultCode,
    required this.opponentName,
    required this.onContinue,
    this.onClaimReward,
    this.isClaiming = false,
    this.claimResponse,
  });

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return Color(normalized.length == 6 ? (0xFF000000 | value) : value);
  }

  String _titleForResult(AppLocalizations l10n, String? resultCode) {
    switch (resultCode) {
      case 'win':
        return l10n.pvpResultVictoryTitle;
      case 'draw':
        return l10n.pvpResultDrawTitle;
      case 'lose':
        return l10n.pvpResultDefeatTitle;
      default:
        return l10n.pvpResultTitle;
    }
  }

  String _subtitleForResult(AppLocalizations l10n, String? resultCode) {
    switch (resultCode) {
      case 'win':
        return opponentName.isEmpty
            ? l10n.pvpResultWinGeneric
            : l10n.pvpResultBeatOpponent(opponentName);
      case 'draw':
        return l10n.pvpResultScoresTied;
      case 'lose':
        if (forcedResultCode == 'lose') {
          return opponentName.isEmpty
              ? l10n.pvpResultForfeitGeneric
              : l10n.pvpResultForfeitOpponentWon(opponentName);
        }
        return l10n.pvpResultTryAgain;
      default:
        return l10n.pvpResultLoadingServer;
    }
  }

  String _localizedTierName(AppLocalizations l10n, PvpRankTierResponse rank) {
    switch (rank.tierCode.trim().toLowerCase()) {
      case 'mam_dong':
        return l10n.pvpTierMamDong;
      case 'la_bac':
        return l10n.pvpTierLaBac;
      case 'nu_vang':
        return l10n.pvpTierNuVang;
      case 'hoa_lam':
        return l10n.pvpTierHoaLam;
      case 'trang_tim':
        return l10n.pvpTierTrangTim;
      case 'tinh_linh_cau_vong':
        return l10n.pvpTierTinhLinhCauVong;
      default:
        final displayName = rank.displayName.trim();
        return displayName.isNotEmpty ? displayName : l10n.pvpTierUnknown;
    }
  }

  String _resultAssetForCode(String? resultCode) {
    return switch (resultCode) {
      'win' => AppAssets.iconWin,
      'lose' => AppAssets.iconLose,
      _ => AppAssets.iconDraw,
    };
  }

  PvpParticipantResponse? _opponentFor(
    PvpMatchResultResponse result,
    PvpParticipantResponse? me,
  ) {
    for (final participant in result.participants) {
      if (!identical(participant, me)) return participant;
    }
    return null;
  }

  int _scoreFor(PvpParticipantResponse? participant) {
    return participant?.score ??
        participant?.validatedSteps ??
        participant?.distanceUnits ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final resultCode =
        (forcedResultCode?.isNotEmpty == true
            ? forcedResultCode!.toLowerCase()
            : null) ??
        result?.resultCodeForUser(currentUserId);
    final myParticipant = result?.participantForUser(currentUserId);
    final opponentParticipant = result == null
        ? null
        : _opponentFor(result!, myParticipant);
    final opponentLabel = opponentName.trim().isNotEmpty
        ? opponentName.trim()
        : (opponentParticipant?.displayName?.trim().isNotEmpty == true
              ? opponentParticipant!.displayName!.trim()
              : l10n.pvpOpponent);
    final materialL10n = MaterialLocalizations.of(context);
    final rank = result?.rankAfter ?? result?.rankBefore;
    final showsRankedProgress =
        result?.isRanked == true && forcedResultCode == null;
    final rankColor =
        _parseHexColor(rank?.colorHex) ?? theme.colorScheme.primary;
    final canClaim =
        showsRankedProgress &&
        result != null &&
        result!.canClaimReward &&
        result!.claimedAt == null &&
        onClaimReward != null &&
        forcedResultCode == null;

    return Container(
      color: Colors.black.withValues(alpha: 0.52),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          key: const ValueKey('pvp-finished-card'),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.authCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.wood,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading && result == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      l10n.pvpLoadingResult,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pvpWaitingServerFinalize,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (result == null) ...[
                    AppIcon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.pvpResultUnavailableTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pvpResultUnavailableMessage,
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Image.asset(
                      _resultAssetForCode(resultCode),
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _titleForResult(l10n, resultCode),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitleForResult(l10n, resultCode),
                      textAlign: TextAlign.center,
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkMuted
                              : AppColors.authCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.wood.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildScoreSide(
                                context,
                                l10n.pvpYou,
                                materialL10n.formatDecimal(
                                  _scoreFor(myParticipant),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '—',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: isDark
                                      ? AppColors.darkMutedForeground
                                      : AppColors.wood,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildScoreSide(
                                context,
                                opponentLabel,
                                materialL10n.formatDecimal(
                                  _scoreFor(opponentParticipant),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showsRankedProgress && rank != null) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildRewardCard(
                              context,
                              result!.tierChanged
                                  ? l10n.pvpNewRank
                                  : l10n.pvpRank,
                              _localizedTierName(l10n, rank),
                              Icons.military_tech,
                              rankColor,
                              leadingAsset: PvpAssetResolver.rankAssetFromTier(
                                rank,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (showsRankedProgress && result!.tierChanged) ...[
                        const SizedBox(height: 12),
                        const PvpFrameAnimation(
                          effectCode: 'rank_up',
                          width: 120,
                          height: 120,
                        ),
                      ],
                      if (showsRankedProgress && result!.claimedAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.pvpRewardClaimed,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Hiển thị chi tiết phần thưởng từ BE sau khi claim
                        if (claimResponse != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.authCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.woodDeep,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.woodDeep.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.pvpRewardsReceived,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? AppColors.darkForeground
                                            : AppColors.wood,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (claimResponse!.walletReward > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            AppAssets.iconDewDrop,
                                            width: 22,
                                            height: 22,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(width: 7),
                                          Flexible(
                                            child: Text(
                                              l10n.pvpCoinReward(
                                                claimResponse!.walletReward,
                                              ),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                color: isDark
                                                    ? AppColors.darkForeground
                                                    : AppColors.woodDeep,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (claimResponse!
                                        .rewardItems
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...claimResponse!.rewardItems.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                AppAssets.iconRewardChest,
                                                width: 21,
                                                height: 21,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(width: 7),
                                              Flexible(
                                                child: Text(
                                                  l10n.pvpItemReward(
                                                    item.quantity,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppColors
                                                              .darkForeground
                                                        : AppColors.woodDeep,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: canClaim ? double.infinity : 190,
                    child: Row(
                      children: [
                        if (canClaim) ...[
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: isClaiming
                                    ? null
                                    : () => onClaimReward?.call(),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.buttonYellow,
                                  foregroundColor: isDark
                                      ? AppColors.darkTextOutline
                                      : AppColors.buttonText,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkTextOutline
                                        : AppColors.woodDeep,
                                    width: 2,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: isClaiming
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        l10n.pvpClaimReward,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Quicksand',
                                          color: isDark
                                              ? AppColors.darkTextOutline
                                              : AppColors.buttonText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: onContinue,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.buttonGreen,
                                foregroundColor: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.buttonText,
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.woodDeep,
                                  width: 2,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                l10n.pvpContinue,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Quicksand',
                                  color: isDark
                                      ? AppColors.darkForeground
                                      : AppColors.buttonText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSide(BuildContext context, String label, String score) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkMutedForeground : AppColors.wood,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? leadingAsset,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkMuted
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkMutedForeground : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingAsset != null)
                Image.asset(leadingAsset, width: 28, height: 28)
              else
                AppIcon(icon, size: 20, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
