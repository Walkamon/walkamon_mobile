import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/friends_response.dart';
import '../../../../data/models/pvp_models.dart';
import '../../../../providers/pvp_provider.dart';

void showIncomingChallengesModal(
  BuildContext context,
  List<PvpInviteResponse> challenges,
  Function(String, String) onAccept,
  Function(String) onReject,
) {
  final pvpProvider = context.read<PvpProvider>();
  pvpProvider.fetchIncomingInvites();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ChangeNotifierProvider<PvpProvider>.value(
      value: pvpProvider,
      child: _IncomingChallengesContent(
        challenges: challenges,
        onAccept: onAccept,
        onReject: onReject,
      ),
    ),
  );
}

class _IncomingChallengesContent extends StatelessWidget {
  final List<PvpInviteResponse> challenges;
  final Function(String, String) onAccept;
  final Function(String) onReject;

  const _IncomingChallengesContent({
    required this.challenges,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerInvites = context.watch<PvpProvider>().incomingInvites;
    final activeChallenges =
        providerInvites.isNotEmpty ? providerInvites : challenges;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lời mời thách đấu',
            style:
                theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (activeChallenges.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Không có lời mời nào',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: activeChallenges.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final challenge = activeChallenges[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                Icons.flash_on,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challenge.user.username.isNotEmpty
                                        ? challenge.user.username
                                        : 'Đối thủ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Lv.15',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
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
                                  onAccept(
                                    challenge.inviteId,
                                    challenge.user.username,
                                  );
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

void showMatchHistoryModal(
  BuildContext context, {
  required String currentUserId,
}) {
  final pvpProvider = context.read<PvpProvider>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ChangeNotifierProvider<PvpProvider>.value(
      value: pvpProvider,
      child: _MatchHistorySheet(currentUserId: currentUserId),
    ),
  );
}

class _MatchHistorySheet extends StatefulWidget {
  final String currentUserId;

  const _MatchHistorySheet({required this.currentUserId});

  @override
  State<_MatchHistorySheet> createState() => _MatchHistorySheetState();
}

class _MatchHistorySheetState extends State<_MatchHistorySheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PvpProvider>().loadMatchHistory(page: 1);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _matchTypeLabel(String code) {
    switch (code.toLowerCase()) {
      case 'ranked':
        return 'Xếp hạng';
      case 'friendly':
        return 'Bạn bè';
      case 'event':
        return 'Sự kiện';
      default:
        return code.isEmpty ? code : code.toUpperCase();
    }
  }

  String _sourceLabel(String? source) {
    switch ((source ?? '').toLowerCase()) {
      case 'bot':
        return 'Bot';
      case 'matchmaking':
        return 'Ghép trận';
      case 'invite':
        return 'Mời';
      default:
        return source ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PvpProvider>();
    final history = provider.matchHistory;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lịch sử thi đấu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (provider.historyTotal > 0)
                Text(
                  '${history.length}/${provider.historyTotal}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              IconButton(
                tooltip: 'Làm mới',
                onPressed: provider.historyLoading
                    ? null
                    : () => provider.loadMatchHistory(page: 1),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: provider.historyMatchType.isEmpty,
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    matchType: '',
                  ),
                ),
                _FilterChip(
                  label: 'Xếp hạng',
                  selected: provider.historyMatchType == 'ranked',
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    matchType: 'ranked',
                  ),
                ),
                _FilterChip(
                  label: 'Bạn bè',
                  selected: provider.historyMatchType == 'friendly',
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    matchType: 'friendly',
                  ),
                ),
                _FilterChip(
                  label: 'Sự kiện',
                  selected: provider.historyMatchType == 'event',
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    matchType: 'event',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Mọi kết quả',
                  selected: provider.historyResultFilter.isEmpty,
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    result: '',
                  ),
                ),
                _FilterChip(
                  label: 'Thắng',
                  selected: provider.historyResultFilter == 'win',
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    result: 'win',
                  ),
                ),
                _FilterChip(
                  label: 'Hủy',
                  selected: provider.historyResultFilter == 'cancelled',
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    result: 'cancelled',
                  ),
                ),
                _FilterChip(
                  label: 'Thua',
                  selected: provider.historyResultFilter == 'lose',
                  onSelected: () => provider.loadMatchHistory(
                    page: 1,
                    result: 'lose',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: provider.historyLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Chưa có trận nào',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final match = history[index];
                      PvpParticipantResponse? me;
                      PvpParticipantResponse? opponent;
                      for (final p in match.participants) {
                        final isMe =
                            widget.currentUserId.isNotEmpty &&
                            p.userId != null &&
                            p.userId == widget.currentUserId;
                        if (isMe) {
                          me = p;
                        } else {
                          opponent ??= p;
                        }
                      }
                      if (me == null) {
                        for (final p in match.participants) {
                          if (p.participantTypeCode.toLowerCase() == 'user' &&
                              p.userId != null &&
                              p.userId!.isNotEmpty) {
                            me = p;
                            break;
                          }
                        }
                      }
                      if (opponent == null || identical(opponent, me)) {
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
                      final isCancelled =
                          match.statusCode.toLowerCase() == 'cancelled' ||
                          resultCode == 'cancelled';
                      final resultLabel = isWin
                          ? 'CHIẾN THẮNG'
                          : isCancelled
                          ? 'HỦY'
                          : resultCode == 'lose'
                          ? 'THẤT BẠI'
                          : isDraw
                          ? 'HÒA'
                          : match.statusCode.toUpperCase();

                      final oppName =
                          opponent?.displayName ??
                          (opponent?.participantTypeCode.toLowerCase() == 'bot'
                              ? 'Bot'
                              : null) ??
                          opponent?.userId ??
                          'Đối thủ';
                      final when = match.endedAt ?? match.createdAt;
                      final dateStr = when != null
                          ? DateFormat('dd/MM HH:mm').format(when.toLocal())
                          : '';
                      final typeLabel = _matchTypeLabel(match.matchTypeCode);
                      final sourceLabel = _sourceLabel(match.sourceCode);
                      final meta = [
                        if (dateStr.isNotEmpty) dateStr,
                        if (typeLabel.isNotEmpty) typeLabel,
                        if (sourceLabel.isNotEmpty) sourceLabel,
                      ].join(' · ');

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.5),
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
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                border: isWin
                                    ? null
                                    : Border.all(color: theme.dividerColor),
                              ),
                              child: Icon(
                                isWin
                                    ? Icons.emoji_events
                                    : isCancelled
                                    ? Icons.block
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
                                  if (meta.isNotEmpty)
                                    Text(
                                      meta,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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
          if (provider.historyTotal > 20) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Trang trước',
                  onPressed:
                      (provider.historyLoading || provider.historyPage <= 1)
                          ? null
                          : () {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                              provider.loadMatchHistory(
                                page: provider.historyPage - 1,
                              );
                            },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Trang ${provider.historyPage} / ${provider.historyTotalPages}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Trang sau',
                  onPressed:
                      (provider.historyLoading ||
                              provider.historyPage >=
                                  provider.historyTotalPages)
                          ? null
                          : () {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                              provider.loadMatchHistory(
                                page: provider.historyPage + 1,
                              );
                            },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

void showFriendsModal(
  BuildContext context,
  List<FriendsResponse> online,
  List<FriendsResponse> offline,
  Function(String userId, String username) onInvite,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        _FriendsModalContent(online: online, offline: offline, onInvite: onInvite),
  );
}

class _FriendsModalContent extends StatelessWidget {
  final List<FriendsResponse> online;
  final List<FriendsResponse> offline;
  final Function(String userId, String username) onInvite;

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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
                  if (online.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Không có bạn bè đang online',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    ...online.map((f) => _buildFriendItem(context, f, onInvite, isOnline: true)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('NGOẠI TUYẾN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (offline.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Không có bạn bè ngoại tuyến',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    ...offline.map((f) => _buildFriendItem(context, f, onInvite, isOnline: false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(
    BuildContext context,
    FriendsResponse friend,
    Function(String userId, String username) onInvite, {
    required bool isOnline,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Lv.15',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isOnline)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final uid =
                    friend.userId.isNotEmpty ? friend.userId : friend.username;
                onInvite(uid, friend.username);
              },
              icon: Icon(
                Icons.sports_kabaddi,
                size: 16,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              label: Text(
                'Thách đấu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
