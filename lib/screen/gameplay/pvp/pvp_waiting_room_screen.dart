import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/pvp_provider.dart';
import '../../../widgets/common/game_back_button.dart';
import '../../../widgets/pet_runtime/pet_runtime_preview.dart';
import 'pvp_asset_resolver.dart';
import 'widgets/pvp_modals.dart';

class PvPWaitingRoomScreen extends StatelessWidget {
  final PvpProvider pvpProvider;
  final VoidCallback? onStartMatchmaking;
  final VoidCallback? onCancelMatchmaking;
  final void Function(String userId, String username)? onInviteFriend;
  final VoidCallback onShowIncomingChallenges;
  final VoidCallback onShowMatchHistory;

  const PvPWaitingRoomScreen({
    super.key,
    required this.pvpProvider,
    required this.onStartMatchmaking,
    required this.onCancelMatchmaking,
    required this.onInviteFriend,
    required this.onShowIncomingChallenges,
    required this.onShowMatchHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    String localized(String vi, String en) => isEnglish ? en : vi;
    final mapAsset = PvpAssetResolver.mapForNow(
      pvpProvider.estimatedServerNow(),
    );
    final affinityCode = pvpProvider.spiritAffinityCode;
    final passiveAsset = PvpAssetResolver.passiveForAffinity(affinityCode);
    final rawAffinity = pvpProvider.spiritAffinity.trim();
    final affinityLabel =
        rawAffinity.isNotEmpty &&
            rawAffinity.toLowerCase() != affinityCode.toLowerCase()
        ? rawAffinity
        : PvpAssetResolver.affinityDisplayName(affinityCode);
    final displayAffinityLabel = isEnglish
        ? <String, String>{
                'warm_sun': 'Warm Sun',
                'dawn': 'Dawn',
                'moonlight': 'Moonlight',
                'sprout': 'Sprout',
              }[affinityCode.toLowerCase()] ??
              affinityLabel
        : affinityLabel;

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
                            tooltip: localized('Lời mời', 'Invites'),
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
                                  '${pvpProvider.incomingInvites.length}',
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
                        tooltip: localized('Lịch sử', 'History'),
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
                                    stageNo: pvpProvider.petStageNo,
                                    animationType: 'idle',
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
                                localized('Bước đi hôm nay:', 'Today steps:'),
                                '${pvpProvider.todaySteps}',
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                localized('Hệ tinh linh:', 'Spirit affinity:'),
                                displayAffinityLabel,
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                localized('Năng lượng:', 'Energy:'),
                                '${pvpProvider.currentEnergy}/${pvpProvider.maxEnergy}',
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                localized('Độ gắn kết:', 'Bond:'),
                                '${pvpProvider.currentBond}',
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
              if (pvpProvider.matchmakingState == PvpMatchmakingState.waiting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    localized(
                      'Đang tìm đối thủ...',
                      'Searching for an opponent...',
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
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
                        ? localized('Hủy tìm trận', 'Cancel search')
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.connecting
                        ? localized('Đang kết nối...', 'Connecting...')
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.countdown
                        ? localized('Đang chuẩn bị...', 'Preparing...')
                        : localized(
                            'Ghép trận ngẫu nhiên',
                            'Find random match',
                          ),
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
                    localized('Thách đấu với bạn bè', 'Challenge a friend'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 100),
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
