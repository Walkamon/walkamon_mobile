import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                            tooltip: 'Lời mời',
                            onPressed: onShowIncomingChallenges,
                            icon: Image.asset(
                              AppAssets.pvpIconInviteFriend,
                              width: 22,
                              height: 22,
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
                        tooltip: 'Lịch sử',
                        onPressed: onShowMatchHistory,
                        icon: Image.asset(
                          AppAssets.pvpIconBattleHistory,
                          width: 22,
                          height: 22,
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
                                'Bước đi hôm nay:',
                                '${pvpProvider.todaySteps}',
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                'Hệ tinh linh:',
                                affinityLabel,
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                'Năng lượng:',
                                '${pvpProvider.currentEnergy}/${pvpProvider.maxEnergy}',
                                theme,
                              ),
                              const SizedBox(height: 8),
                              _buildStatRow(
                                'Độ gắn kết:',
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
                    'Đang tìm đối thủ...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
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
                  icon: Image.asset(
                    AppAssets.pvpIconAutoBattle,
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    pvpProvider.matchmakingState == PvpMatchmakingState.waiting
                        ? 'Hủy tìm trận'
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.connecting
                        ? 'Đang kết nối...'
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.countdown
                        ? 'Đang chuẩn bị...'
                        : 'Ghép trận ngẫu nhiên',
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
                child: OutlinedButton.icon(
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
                  icon: Image.asset(
                    AppAssets.pvpIconChallenge,
                    width: 24,
                    height: 24,
                  ),
                  label: const Text(
                    'Thách đấu với bạn bè',
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
