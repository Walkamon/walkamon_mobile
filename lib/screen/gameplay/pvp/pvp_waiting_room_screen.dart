import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/pvp_provider.dart';
import '../../../widgets/common/game_back_button.dart';
import '../../../widgets/pet_runtime/pet_runtime_preview.dart';
import 'pvp_asset_resolver.dart';
import 'widgets/pvp_modals.dart';

class PvPWaitingRoomScreen extends StatelessWidget {
  final PvpProvider pvpProvider;
  final String activePetAffinityCode;
  final int activePetStageNo;
  final String activePetAnimationType;
  final VoidCallback? onStartMatchmaking;
  final VoidCallback? onCancelMatchmaking;
  final void Function(String userId, String username)? onInviteFriend;
  final VoidCallback onShowIncomingChallenges;
  final VoidCallback onShowMatchHistory;

  const PvPWaitingRoomScreen({
    super.key,
    required this.pvpProvider,
    required this.activePetAffinityCode,
    required this.activePetStageNo,
    this.activePetAnimationType = 'idle',
    required this.onStartMatchmaking,
    required this.onCancelMatchmaking,
    required this.onInviteFriend,
    required this.onShowIncomingChallenges,
    required this.onShowMatchHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final mapAsset = PvpAssetResolver.mapForNow(
      pvpProvider.estimatedServerNow(),
    );
    final affinityCode = activePetAffinityCode.trim().isEmpty
        ? pvpProvider.spiritAffinityCode
        : activePetAffinityCode.trim();
    final stageNo = activePetAffinityCode.trim().isEmpty
        ? pvpProvider.petStageNo
        : activePetStageNo;
    final passiveAsset = PvpAssetResolver.passiveForAffinity(affinityCode);
    final displayAffinityLabel = switch (affinityCode.toLowerCase()) {
      'warm_sun' => l10n.pvpAffinityWarmSun,
      'dawn' => l10n.pvpAffinityDawn,
      'moonlight' => l10n.pvpAffinityMoonlight,
      'sprout' => l10n.pvpAffinitySprout,
      _ => l10n.pvpAffinityUnknown,
    };
    final isSearchingForOpponent =
        pvpProvider.matchmakingState == PvpMatchmakingState.waiting;
    // Use part of the reserved bottom-navigation gap for the search status so
    // the hero/stats viewport does not shrink and clip the Bond row.
    const matchmakingStatusExtent = 30.0;
    const bottomNavigationClearance = 100.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          mapAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
        Container(color: Colors.black.withOpacity(0.28)),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 8,
            20,
            16,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GameBackButton(
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamed(context, '/home');
                      }
                    },
                  ),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.authCard,
                              side: const BorderSide(
                                color: AppColors.woodDeep,
                                width: 2,
                              ),
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(8),
                            ),
                            tooltip: l10n.pvpInvites,
                            onPressed: onShowIncomingChallenges,
                            icon: Image.asset(
                              AppAssets.pvpIconInviteFriend,
                              width: 32,
                              height: 32,
                            ),
                          ),
                          if (pvpProvider.incomingInvites.isNotEmpty)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  numberFormat.format(
                                    pvpProvider.incomingInvites.length,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.authCard,
                          side: const BorderSide(
                            color: AppColors.woodDeep,
                            width: 2,
                          ),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: l10n.pvpHistory,
                        onPressed: onShowMatchHistory,
                        icon: Image.asset(
                          AppAssets.pvpIconBattleHistory,
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 168,
                              height: 168,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.75),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withAlpha(
                                      90,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: PetRuntimePreview(
                                    affinityCode: affinityCode,
                                    stageNo: stageNo,
                                    animationType:
                                        activePetAnimationType.trim().isEmpty
                                        ? 'idle'
                                        : activePetAnimationType.trim(),
                                    compact: true,
                                    height: 144,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Image.asset(
                                PvpAssetResolver.rankAsset(),
                                width: 52,
                                height: 52,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (passiveAsset != null)
                              Positioned(
                                left: -4,
                                top: -4,
                                child: Image.asset(
                                  passiveAsset,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(13),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                pvpProvider.petName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 24),
                              _buildStatRow(
                                l10n.pvpTodayStepsLabel,
                                numberFormat.format(pvpProvider.todaySteps),
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                l10n.pvpSpiritAffinityLabel,
                                displayAffinityLabel,
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                l10n.pvpEnergyLabel,
                                '${numberFormat.format(pvpProvider.currentEnergy)}/${numberFormat.format(pvpProvider.maxEnergy)}',
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                l10n.pvpBondLabel,
                                numberFormat.format(pvpProvider.currentBond),
                                theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (isSearchingForOpponent)
                SizedBox(
                  height: matchmakingStatusExtent,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      l10n.pvpSearchingOpponent,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6C95D),
                    foregroundColor: AppColors.woodDeep,
                    side: const BorderSide(color: AppColors.woodDeep, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed:
                      pvpProvider.matchmakingState ==
                          PvpMatchmakingState.waiting
                      ? onCancelMatchmaking
                      : pvpProvider.matchmakingState ==
                                PvpMatchmakingState.idle ||
                            pvpProvider.matchmakingState ==
                                PvpMatchmakingState.finished ||
                            pvpProvider.matchmakingState ==
                                PvpMatchmakingState.cancelled
                      ? onStartMatchmaking
                      : null,
                  child: Text(
                    pvpProvider.matchmakingState == PvpMatchmakingState.waiting
                        ? l10n.pvpCancelSearch
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.connecting
                        ? l10n.pvpConnecting
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.countdown
                        ? l10n.pvpPreparing
                        : l10n.pvpFindRandomMatch,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.authCard,
                    foregroundColor: AppColors.woodDeep,
                    side: const BorderSide(color: AppColors.woodDeep, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: onInviteFriend == null
                      ? null
                      : () {
                          final online = pvpProvider.friendsList
                              .where((f) => f.isOnline)
                              .toList();
                          final offline = pvpProvider.friendsList
                              .where((f) => !f.isOnline)
                              .toList();
                          showFriendsModal(
                            context,
                            online,
                            offline,
                            (userId, username) =>
                                onInviteFriend!(userId, username),
                          );
                        },
                  child: Text(
                    l10n.pvpChallengeFriend,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                height: isSearchingForOpponent
                    ? bottomNavigationClearance - matchmakingStatusExtent
                    : bottomNavigationClearance,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
