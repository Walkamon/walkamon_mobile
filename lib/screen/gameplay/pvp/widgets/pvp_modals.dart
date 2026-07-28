import 'package:flutter/material.dart';
import '../../../../data/models/pvp_models.dart';
import '../../../../data/models/friends_response.dart';
import 'package:intl/intl.dart';

void showIncomingChallengesModal(BuildContext context, List<PvpInviteResponse> challenges, Function(String, String) onAccept, Function(String) onReject) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _IncomingChallengesContent(
      challenges: challenges,
      onAccept: onAccept,
      onReject: onReject,
    ),
  );
}

class _IncomingChallengesContent extends StatelessWidget {
  final List<PvpInviteResponse> challenges;
  final Function(String, String) onAccept;
  final Function(String) onReject;

  const _IncomingChallengesContent({required this.challenges, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lời mời thách đấu',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (challenges.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('Không có lời mời nào', style: TextStyle(fontWeight: FontWeight.w500)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: challenges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Icon(Icons.flash_on, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(challenge.user.username.isNotEmpty ? challenge.user.username : 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Lv.15', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onAccept(challenge.inviteId, challenge.user.username);
                                },
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Chấp nhận'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onReject(challenge.inviteId);
                                },
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Từ chối'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

void showMatchHistoryModal(BuildContext context, List<PvpMatchResponse> history, String currentUserId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MatchHistoryContent(history: history, currentUserId: currentUserId),
  );
}

class _MatchHistoryContent extends StatelessWidget {
  final List<PvpMatchResponse> history;
  final String currentUserId;

  const _MatchHistoryContent({required this.history, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lịch sử thi đấu',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = history[index];

                PvpParticipantResponse? me;
                PvpParticipantResponse? opponent;
                for (final p in match.participants) {
                  final isMe = currentUserId.isNotEmpty &&
                      p.userId != null &&
                      p.userId == currentUserId;
                  if (isMe) {
                    me = p;
                  } else {
                    opponent ??= p;
                  }
                }
                if (me == null) {
                  for (final p in match.participants) {
                    if (p.userId != null && p.userId!.isNotEmpty) {
                      me = p;
                      break;
                    }
                  }
                }
                if (opponent == null ||
                    (me != null &&
                        opponent.userId != null &&
                        opponent.userId == me.userId)) {
                  for (final p in match.participants) {
                    if (!identical(p, me)) {
                      opponent = p;
                      break;
                    }
                  }
                }

                final resultCode = me?.resultCode?.toLowerCase();
                final isWin = resultCode == 'win';
                final isDraw = resultCode == 'draw';
                final resultLabel = isWin
                    ? 'CHIẾN THẮNG'
                    : isDraw
                    ? 'HÒA'
                    : resultCode == 'lose'
                    ? 'THẤT BẠI'
                    : (match.statusCode.toLowerCase() == 'cancelled'
                        ? 'HỦY'
                        : match.statusCode.toUpperCase());

                final oppName =
                    opponent?.displayName ?? opponent?.userId ?? 'Unknown';
                final dateStr = match.createdAt != null
                    ? DateFormat('dd/MM HH:mm').format(match.createdAt!)
                    : '';
                final matchType = match.matchTypeCode.toUpperCase();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWin
                              ? Colors.amber.withOpacity(0.2)
                              : theme.colorScheme.surfaceContainerHighest,
                          border: isWin
                              ? null
                              : Border.all(color: theme.dividerColor),
                        ),
                        child: Icon(
                          isWin
                              ? Icons.emoji_events
                              : isDraw
                              ? Icons.handshake
                              : Icons.close,
                          color: isWin
                              ? Colors.amber
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              oppName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              dateStr.isEmpty
                                  ? matchType
                                  : '$dateStr · $matchType',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        resultLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: isWin
                              ? Colors.amber
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showFriendsModal(BuildContext context, List<FriendsResponse> online, List<FriendsResponse> offline, Function(String) onInvite) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FriendsModalContent(online: online, offline: offline, onInvite: onInvite),
  );
}

class _FriendsModalContent extends StatelessWidget {
  final List<FriendsResponse> online;
  final List<FriendsResponse> offline;
  final Function(String) onInvite;

  const _FriendsModalContent({required this.online, required this.offline, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thách đấu Bạn bè',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('ĐANG ONLINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...online.map((f) => _buildFriendItem(context, f, onInvite)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('NGOẠI TUYẾN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...offline.map((f) => _buildFriendItem(context, f, onInvite)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(BuildContext context, FriendsResponse friend, Function(String) onInvite) {
    final theme = Theme.of(context);
    final isOnline = true; // Hardcoded since API missing isOnline
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOnline ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isOnline ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant)),
                Text('Lv.15', style: TextStyle(color: isOnline ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          if (isOnline)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onInvite(friend.username);
              },
              icon: const Icon(Icons.sports_kabaddi, size: 16),
              label: const Text('Thách đấu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}
