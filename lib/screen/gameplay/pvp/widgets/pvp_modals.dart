import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/friends_response.dart';
import '../../../../data/models/pvp_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/pvp_provider.dart';
import '../../../../widgets/common/app_icon.dart';
import '../../../../widgets/common/asset_only_icon_button.dart';
import '../../../../widgets/common/game_button_label.dart';

String? _nonBlank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

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
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final providerInvites = context.watch<PvpProvider>().incomingInvites;
    final activeChallenges = providerInvites.isNotEmpty
        ? providerInvites
        : challenges;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.authCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        minHeight: 280,
        maxHeight: MediaQuery.of(context).size.height * 0.72,
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
          Text(
            l10n.pvpChallengeInvitesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (activeChallenges.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                l10n.pvpNoInvitations,
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
                  final senderOnline = challenge.otherUserIsOnline;
                  final senderCode = challenge.otherUserPvpAvailabilityCode;
                  final canAccept = challenge.canAccept;

                  String presenceLabel;
                  Color presenceColor;
                  if (!senderOnline) {
                    presenceLabel = l10n.pvpStatusOffline;
                    presenceColor = Colors.grey;
                  } else if (senderCode == 'busy') {
                    presenceLabel = l10n.pvpStatusBusy;
                    presenceColor = Colors.orange;
                  } else {
                    presenceLabel = l10n.pvpStatusOnline;
                    presenceColor = Colors.green;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
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
                              child: AppIcon(
                                Icons.flash_on,
                                asset: AppAssets.iconOpponent,
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
                                        : l10n.pvpOpponent,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: presenceColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        presenceLabel,
                                        style: TextStyle(
                                          color: presenceColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!canAccept && senderOnline && senderCode == 'busy')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                AppIcon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.pvpSenderInAnotherMatch,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!canAccept && !senderOnline)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                AppIcon(
                                  Icons.wifi_off,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.pvpSenderOffline,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: canAccept
                                    ? () {
                                        Navigator.pop(context);
                                        onAccept(
                                          challenge.inviteId,
                                          challenge.user.username,
                                        );
                                      }
                                    : null,
                                icon: const AppIcon(Icons.check, size: 16),
                                label: Text(l10n.pvpAccept),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.darkLife
                                      : AppColors.buttonGreen,
                                  foregroundColor: isDark
                                      ? AppColors.darkTextOutline
                                      : AppColors.buttonText,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.woodDeep,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.darkMuted
                                      : AppColors.buttonSecondary,
                                  foregroundColor: isDark
                                      ? AppColors.darkForeground
                                      : AppColors.woodDeep,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.woodDeep,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  onReject(challenge.inviteId);
                                },
                                icon: const AppIcon(Icons.close, size: 28),
                                label: Text(l10n.pvpReject),
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

  String _matchTypeLabel(String code, AppLocalizations l10n) {
    switch (code.toLowerCase()) {
      case 'ranked':
        return l10n.pvpMatchTypeRanked;
      case 'friendly':
        return l10n.pvpMatchTypeFriendly;
      case 'event':
        return l10n.pvpMatchTypeEvent;
      default:
        return code.isEmpty ? '' : l10n.pvpMatchTypeOther;
    }
  }

  String _sourceLabel(String? source, AppLocalizations l10n) {
    switch ((source ?? '').toLowerCase()) {
      case 'bot':
        return l10n.pvpMatchSourceBot;
      case 'matchmaking':
        return l10n.pvpMatchSourceMatchmaking;
      case 'invite':
        return l10n.pvpMatchSourceInvite;
      default:
        return source?.isNotEmpty == true ? l10n.pvpMatchSourceOther : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final alwaysUse24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);
    final provider = context.watch<PvpProvider>();
    final history = provider.matchHistory;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.authCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.74,
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
                  l10n.pvpMatchHistoryTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (provider.historyTotal > 0)
                Text(
                  '${materialL10n.formatDecimal(history.length)}/${materialL10n.formatDecimal(provider.historyTotal)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 14),
              AssetOnlyIconButton(
                semanticLabel: l10n.pvpRefresh,
                onPressed: provider.historyLoading
                    ? null
                    : () => provider.loadMatchHistory(page: 1),
                icon: Icons.refresh,
                buttonSize: 48,
                assetSize: 42,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.pvpFilterAll,
                  selected: provider.historyMatchType.isEmpty,
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, matchType: ''),
                ),
                _FilterChip(
                  label: l10n.pvpMatchTypeRanked,
                  selected: provider.historyMatchType == 'ranked',
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, matchType: 'ranked'),
                ),
                _FilterChip(
                  label: l10n.pvpMatchTypeFriendly,
                  selected: provider.historyMatchType == 'friendly',
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, matchType: 'friendly'),
                ),
                _FilterChip(
                  label: l10n.pvpMatchTypeEvent,
                  selected: provider.historyMatchType == 'event',
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, matchType: 'event'),
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
                  label: l10n.pvpFilterAllResults,
                  selected: provider.historyResultFilter.isEmpty,
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, result: ''),
                ),
                _FilterChip(
                  label: l10n.pvpFilterWins,
                  selected: provider.historyResultFilter == 'win',
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, result: 'win'),
                ),

                _FilterChip(
                  label: l10n.pvpFilterLosses,
                  selected: provider.historyResultFilter == 'lose',
                  onSelected: () =>
                      provider.loadMatchHistory(page: 1, result: 'lose'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: history.isEmpty
                ? 190
                : MediaQuery.sizeOf(context).height * 0.45,
            child: provider.historyLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        l10n.pvpNoMatches,
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
                          ? l10n.pvpHistoryVictory
                          : isCancelled
                          ? l10n.pvpHistoryCancelled
                          : resultCode == 'lose'
                          ? l10n.pvpHistoryDefeat
                          : isDraw
                          ? l10n.pvpHistoryDraw
                          : l10n.pvpHistoryResultUnknown;

                      final oppName =
                          _nonBlank(opponent?.displayName) ??
                          (opponent?.participantTypeCode.toLowerCase() == 'bot'
                              ? l10n.pvpMatchSourceBot
                              : null) ??
                          l10n.pvpOpponent;
                      final when = match.endedAt ?? match.createdAt;
                      final localWhen = when?.toLocal();
                      final dateStr = localWhen != null
                          ? '${materialL10n.formatShortDate(localWhen)} ${materialL10n.formatTimeOfDay(TimeOfDay.fromDateTime(localWhen), alwaysUse24HourFormat: alwaysUse24HourFormat)}'
                          : '';
                      final typeLabel = _matchTypeLabel(
                        match.matchTypeCode,
                        l10n,
                      );
                      final sourceLabel = _sourceLabel(match.sourceCode, l10n);
                      final meta = [
                        if (dateStr.isNotEmpty) dateStr,
                        if (typeLabel.isNotEmpty) typeLabel,
                        if (sourceLabel.isNotEmpty) sourceLabel,
                      ].join(' · ');

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkNestedCard.withValues(alpha: 0.98)
                              : AppColors.creamLight.withValues(alpha: 0.82),
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
                                    ? (isDark
                                          ? AppColors.darkLife.withValues(
                                              alpha: 0.2,
                                            )
                                          : Colors.amber.withValues(alpha: 0.2))
                                    : theme.colorScheme.surfaceContainerHighest,
                                border: isWin
                                    ? null
                                    : Border.all(color: theme.dividerColor),
                              ),
                              child: AppIcon(
                                isWin
                                    ? Icons.emoji_events
                                    : isCancelled
                                    ? Icons.block
                                    : isDraw
                                    ? Icons.handshake
                                    : Icons.close,
                                asset: isWin
                                    ? AppAssets.iconWin
                                    : isCancelled
                                    ? AppAssets.iconCancel
                                    : isDraw
                                    ? AppAssets.iconDraw
                                    : AppAssets.iconLose,
                                color: isWin
                                    ? Colors.amber
                                    : theme.colorScheme.onSurfaceVariant,
                                size: !isWin && !isCancelled && !isDraw
                                    ? 28
                                    : 24,
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
                  icon: const AppIcon(Icons.chevron_left),
                  tooltip: l10n.pvpPreviousPage,
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
                    l10n.pvpPageOf(
                      provider.historyPage,
                      provider.historyTotalPages,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const AppIcon(Icons.chevron_right),
                  tooltip: l10n.pvpNextPage,
                  onPressed:
                      (provider.historyLoading ||
                          provider.historyPage >= provider.historyTotalPages)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: isDark ? AppColors.darkPrimary : AppColors.buttonGreen,
        backgroundColor: isDark
            ? AppColors.darkNestedCard
            : AppColors.buttonSecondary,
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.woodDeep,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        showCheckmark: selected,
        checkmarkColor: isDark ? AppColors.darkForeground : AppColors.oliveDeep,
        labelStyle: TextStyle(
          color: selected
              ? (isDark ? AppColors.darkForeground : AppColors.buttonText)
              : (isDark ? AppColors.darkForeground : AppColors.woodDeep),
          fontWeight: FontWeight.w800,
          fontSize: 13,
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
    builder: (context) => _FriendsModalContent(
      online: online,
      offline: offline,
      onInvite: onInvite,
    ),
  );
}

class _FriendsModalContent extends StatelessWidget {
  final List<FriendsResponse> online;
  final List<FriendsResponse> offline;
  final Function(String userId, String username) onInvite;

  const _FriendsModalContent({
    required this.online,
    required this.offline,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.authCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.wood, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.creamDeep,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          GameButtonLabel(
            l10n.pvpChallengeFriendsTitle,
            fontSize: 22,
            color: AppColors.woodDeep,
            outlineColor: AppColors.authCard,
            outlineWidth: 3,
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPresenceSection(
                    context,
                    label: l10n.pvpOnlineSection,
                    emptyLabel: l10n.pvpNoOnlineFriends,
                    friends: online,
                    online: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Divider(color: AppColors.wood, thickness: 1.5),
                  ),
                  _buildPresenceSection(
                    context,
                    label: l10n.pvpOfflineSection,
                    emptyLabel: l10n.pvpNoOfflineFriends,
                    friends: offline,
                    online: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceSection(
    BuildContext context, {
    required String label,
    required String emptyLabel,
    required List<FriendsResponse> friends,
    required bool online,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Image.asset(
              online ? AppAssets.iconOnline : AppAssets.iconOffline,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: online ? AppColors.success : AppColors.outlineBrown,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.woodDeep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyLabel,
              style: const TextStyle(
                color: AppColors.outlineBrown,
                fontSize: 14,
              ),
            ),
          )
        else
          ...friends.map((f) => _buildFriendItem(context, f, onInvite)),
      ],
    );
  }

  Widget _buildFriendItem(
    BuildContext context,
    FriendsResponse friend,
    Function(String userId, String username) onInvite,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canChallenge = friend.isPvpAvailable;
    final isBusy = friend.isPvpBusy;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wood, width: 1.5),
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
                    color: AppColors.woodDeep,
                  ),
                ),
                if (isBusy)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.pvpStatusBusy,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                else if (friend.isOnline)
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.pvpStatusOnline,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    l10n.pvpStatusOffline,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (friend.isOnline)
            Tooltip(
              message: isBusy ? l10n.pvpFriendBusy : l10n.pvpChallengeAction,
              child: ElevatedButton.icon(
                onPressed: canChallenge
                    ? () {
                        Navigator.pop(context);
                        final uid = friend.userId.isNotEmpty
                            ? friend.userId
                            : friend.username;
                        onInvite(uid, friend.username);
                      }
                    : null,
                icon: AppIcon(
                  isBusy ? Icons.hourglass_top : Icons.sports_kabaddi,
                  asset: isBusy ? AppAssets.iconTired : AppAssets.iconChallenge,
                  size: 16,
                  color: canChallenge
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                label: Text(
                  isBusy ? l10n.pvpStatusBusy : l10n.pvpChallengeAction,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canChallenge
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canChallenge
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
