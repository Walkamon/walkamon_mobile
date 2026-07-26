import 'package:flutter/material.dart';

import '../../../providers/pvp_provider.dart';
import 'widgets/pvp_modals.dart';

class PvPWaitingRoomScreen extends StatelessWidget {
  final PvpProvider pvpProvider;
  final VoidCallback? onStartMatchmaking;
  final void Function(String name)? onInviteFriend;
  final VoidCallback onShowIncomingChallenges;
  final VoidCallback onShowMatchHistory;

  const PvPWaitingRoomScreen({
    super.key,
    required this.pvpProvider,
    required this.onStartMatchmaking,
    required this.onInviteFriend,
    required this.onShowIncomingChallenges,
    required this.onShowMatchHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.filledTonal(
                    onPressed: onShowIncomingChallenges,
                    icon: const Icon(Icons.mail),
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
              IconButton.filledTonal(
                onPressed: onShowMatchHistory,
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${pvpProvider.petName}',
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
                            pvpProvider.spiritAffinity,
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onStartMatchmaking,
              icon: const Icon(Icons.sports_kabaddi),
              label: const Text(
                'Ghép trận ngẫu nhiên',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  : () => showFriendsModal(
                      context,
                      pvpProvider.friendsList,
                      [],
                      onInviteFriend!,
                    ),
              icon: const Icon(Icons.people),
              label: const Text(
                'Thách đấu với bạn bè',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
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
