import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../data/models/pvp_models.dart';
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
                  color: Colors.green.withOpacity(0.2),
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
  const PvPMatchSuccessOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  AppAssets.pvpIconAutoBattle,
                  width: 48,
                  height: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.pvpMatchSuccess,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pvpEnteringRace,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
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

  String _formatMmrDelta(int delta, MaterialLocalizations materialL10n) {
    final formatted = materialL10n.formatDecimal(delta);
    return delta > 0 ? '+$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final resultCode =
        (forcedResultCode?.isNotEmpty == true
            ? forcedResultCode!.toLowerCase()
            : null) ??
        result?.resultCodeForUser(currentUserId);
    final rank = result?.rankAfter ?? result?.rankBefore;
    final rankColor =
        _parseHexColor(rank?.colorHex) ?? theme.colorScheme.primary;
    final canClaim =
        result != null &&
        result!.canClaimReward &&
        result!.claimedAt == null &&
        onClaimReward != null &&
        forcedResultCode == null;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
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
                  const SizedBox(height: 24),
                  Text(
                    _titleForResult(l10n, resultCode),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitleForResult(l10n, resultCode),
                    textAlign: TextAlign.center,
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        if (result!.isRanked) ...[
                          _buildRewardCard(
                            context,
                            l10n.pvpMmr,
                            _formatMmrDelta(result!.mmrDelta, materialL10n),
                            Icons.trending_up,
                            result!.mmrDelta >= 0
                                ? Colors.amber
                                : theme.colorScheme.error,
                          ),
                          _buildRewardCard(
                            context,
                            l10n.pvpCurrentMmr,
                            materialL10n.formatDecimal(result!.mmrAfter),
                            Icons.speed,
                            theme.colorScheme.primary,
                          ),
                        ],
                        if (rank != null)
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
                    if (result!.tierChanged) ...[
                      const SizedBox(height: 12),
                      const PvpFrameAnimation(
                        effectCode: 'rank_up',
                        width: 120,
                        height: 120,
                      ),
                    ],
                    if (result!.claimedAt != null) ...[
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.pvpRewardsReceived,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (claimResponse!.walletReward > 0)
                                Row(
                                  children: [
                                    const AppIcon(
                                      Icons.monetization_on,
                                      size: 20,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.pvpCoinReward(
                                        claimResponse!.walletReward,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              if (claimResponse!.rewardItems.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ...claimResponse!.rewardItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const AppIcon(
                                          Icons.card_giftcard,
                                          asset: AppAssets.iconRewardChest,
                                          size: 18,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.pvpItemReward(item.quantity),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
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
                      ],
                    ],
                  ],
                ],
                const SizedBox(height: 32),
                if (canClaim) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isClaiming
                          ? null
                          : () => onClaimReward?.call(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: isClaiming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.pvpClaimReward,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      l10n.pvpContinue,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
