import 'package:flutter/material.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/game_back_button.dart';
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_async_state.dart';
import '../../core/theme/app_colors.dart';
import '../profile/friend_player_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isEmbedded;
  final LeaderboardRepository? repository;

  const LeaderboardScreen({
    super.key,
    this.isEmbedded = false,
    this.repository,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final LeaderboardRepository _repository;

  final String _scope = 'global';
  String _timeFrame = 'daily';
  String _metric = 'steps';
  bool _isLoading = true;
  String? _errorMessage;
  List<_UserRank> _users = [];
  int? _myRank;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LeaderboardRepository();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.getLeaderboard(
        _mapTimeFrameToBackend(_timeFrame),
      );
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _users = response.data!.leaderboard
              .map(
                (item) => _UserRank(
                  id: item.userId,
                  name:
                      item.username ??
                      AppLocalizations.of(context).leaderboardUserDefault,
                  steps: {
                    'daily': item.stepCount,
                    'weekly': item.stepCount,
                    'monthly': item.stepCount,
                  },
                  level: 0,
                  isMe: item.isCurrentUser,
                  isFriend: true,
                  rank: item.rank,
                ),
              )
              .toList();
          _myRank = response.data!.myRank;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : AppLocalizations.of(context).leaderboardCouldNotLoad;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context).leaderboardCouldNotConnect;
        _isLoading = false;
      });
    }
  }

  String _mapTimeFrameToBackend(String timeFrame) {
    switch (timeFrame) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Daily';
    }
  }

  List<_UserRank> get _sortedUsers {
    final filtered = _users.where((user) {
      if (_scope == 'friends') {
        return user.isFriend || user.isMe;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_metric == 'level') {
        return b.level.compareTo(a.level);
      }
      return b.steps[_timeFrame]!.compareTo(a.steps[_timeFrame]!);
    });

    return filtered;
  }

  List<_UserRank> get _top3 => _sortedUsers.take(3).toList();
  List<_UserRank> get _rest => _sortedUsers.skip(3).take(7).toList();
  int get _myIndex => _sortedUsers.indexWhere((user) => user.isMe);
  bool get _isMeOutsideTop10 => _myIndex >= 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkMuted : AppColors.leafLight;
    final sortedUsers = _sortedUsers;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, widget.isEmbedded ? 2 : 18, 18, 4),
      child: Column(
        children: [
          if (!widget.isEmbedded) ...[
            Row(
              children: [
                GameBackButton(
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Center(
                    child: GameButtonLabel(
                      l10n.leaderboardTitle,
                      fontSize: 20,
                      color: AppColors.woodDeep,
                      outlineColor: AppColors.authCard,
                      outlineWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
                final bottomClearance = widget.isEmbedded
                    ? 80.0 + systemBottom.clamp(10.0, 40.0).toDouble()
                    : 0.0;
                final maxPanelHeight = (constraints.maxHeight - bottomClearance)
                    .clamp(0.0, constraints.maxHeight);
                final contentHeight = _isLoading || _errorMessage != null
                    ? 350.0
                    : 198.0 + (sortedUsers.length * 59.0);
                final panelHeight = contentHeight.clamp(0.0, maxPanelHeight);

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: panelHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                          decoration: BoxDecoration(
                            color: panelColor.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.woodDeep,
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.woodDeep.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildCompactPeriodSelector(l10n),
                              const SizedBox(height: 7),
                              _buildMetricDropdown(l10n),
                              const SizedBox(height: 7),
                              _buildTableHeader(),
                              const SizedBox(height: 5),
                              Expanded(
                                child: _buildCompactRankingContent(sortedUsers),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 42,
                          right: 42,
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 132),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.woodLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.woodDeep,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.woodDeep.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GameButtonLabel(
                                l10n.leaderboardTitle,
                                fontSize: 16,
                                outlineWidth: 2.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPeriodSelector(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    final textColor = isDark ? AppColors.darkForeground : AppColors.inkBrown;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.buttonGreen;
    final frames = [
      ('daily', l10n.leaderboardToday),
      ('weekly', l10n.leaderboardThisWeek),
      ('monthly', l10n.leaderboardThisMonth),
    ];

    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wood, width: 1.4),
      ),
      child: Row(
        children: frames.map((frame) {
          final active = _timeFrame == frame.$1;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (active) return;
                setState(() => _timeFrame = frame.$1);
                _loadLeaderboard();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: active
                        ? (isDark ? AppColors.darkBorder : AppColors.woodDeep)
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: active
                    ? GameButtonLabel(
                        frame.$2,
                        fontSize: 10.5,
                        outlineWidth: 1.8,
                      )
                    : Text(
                        frame.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableHeader() {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.wood, width: 1.2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              isVietnamese ? 'Hạng' : 'Rank',
              style: _tableHeaderStyle(context),
            ),
          ),
          Expanded(
            child: Text(
              isVietnamese ? 'Người chơi' : 'Player',
              style: _tableHeaderStyle(context),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              isVietnamese ? 'Điểm số' : 'Score',
              textAlign: TextAlign.right,
              style: _tableHeaderStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkForeground
        : AppColors.inkBrown,
    fontSize: 11,
    fontWeight: FontWeight.w900,
  );

  Widget _buildMetricDropdown(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.inkBrown;
    final selectedLabel = _metric == 'steps'
        ? l10n.leaderboardSteps
        : l10n.leaderboardLevel;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 146,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return PopupMenuButton<String>(
              initialValue: _metric,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 6),
              color: isDark ? AppColors.darkCard : AppColors.authCard,
              surfaceTintColor: Colors.transparent,
              elevation: 7,
              constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.wood, width: 2),
              ),
              onSelected: (selected) {
                if (selected == _metric) return;
                setState(() => _metric = selected);
              },
              itemBuilder: (context) => [
                _buildMetricPopupItem(
                  value: 'steps',
                  label: l10n.leaderboardSteps,
                  selected: _metric == 'steps',
                ),
                _buildMetricPopupItem(
                  value: 'level',
                  label: l10n.leaderboardLevel,
                  selected: _metric == 'level',
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkMuted : AppColors.creamLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.wood, width: 1.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppIcon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 23,
                      color: AppColors.woodDeep,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMetricPopupItem({
    required String value,
    required String label,
    required bool selected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuItem<String>(
      value: value,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkPrimary : AppColors.leafLight)
              : (isDark
                    ? AppColors.darkMuted
                    : AppColors.creamLight.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.oliveDeep : AppColors.creamDeep,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              AppIcon(
                Icons.check_rounded,
                size: 22,
                color: isDark ? AppColors.darkForeground : AppColors.oliveDeep,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRankingContent(List<_UserRank> sortedUsers) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Center(child: GameLoadingIndicator(label: l10n.loading));
    }

    if (_errorMessage != null) {
      return GameAsyncStatePanel(
        message: _errorMessage!,
        isError: true,
        onRetry: _loadLeaderboard,
        retryLabel: l10n.retry,
      );
    }

    if (sortedUsers.isEmpty) {
      return GameAsyncStatePanel(message: l10n.leaderboardCouldNotLoad);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: sortedUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 5),
      itemBuilder: (_, index) =>
          _buildCompactRankRow(sortedUsers[index], index + 1),
    );
  }

  Widget _buildCompactRankRow(_UserRank user, int rank) {
    final l10n = AppLocalizations.of(context);
    final displayName = user.isMe ? l10n.leaderboardYou : user.name;
    final value = _metric == 'level'
        ? 'Lv.${user.level}'
        : _formatNumber(user.steps[_timeFrame] ?? 0);

    void openProfile() {
      if (user.isMe || user.id.isEmpty) return;
      Navigator.pushNamed(
        context,
        '/profile/friend',
        arguments: FriendPlayerProfileArguments(
          userId: user.id,
          initialName: user.name,
        ),
      );
    }

    return Material(
      color: user.isMe
          ? AppColors.leafBright.withValues(alpha: 0.84)
          : AppColors.authCard.withValues(alpha: 0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: user.isMe ? AppColors.oliveDeep : AppColors.wood,
          width: user.isMe ? 1.8 : 1.4,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: user.isMe || user.id.isEmpty ? null : openProfile,
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(
              children: [
                SizedBox(width: 50, child: _buildRankBadge(rank)),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.creamDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.wood, width: 1.3),
                  ),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.woodDeep,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkBrown,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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

  Widget _buildRankBadge(int rank) {
    if (rank > 3) {
      return Text(
        '$rank',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.inkBrown,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    final color = switch (rank) {
      1 => AppColors.gold,
      2 => AppColors.sky,
      _ => AppColors.woodLight,
    };

    return Stack(
      alignment: Alignment.center,
      children: [
        AppIcon(Icons.star_rounded, size: 39, color: color),
        Text(
          '$rank',
          style: const TextStyle(
            color: AppColors.buttonText,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: AppColors.woodDeep,
                blurRadius: 1,
                offset: Offset(0.7, 0.7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Keep the previous widget tree during the visual migration so a running
  // debug session can hot reload without changing state fields.
  // ignore: unused_element
  Widget _buildLegacyLeaderboard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final sortedUsers = _sortedUsers;
    final top3 = _top3;
    final rest = _rest;

    if (_isLoading) {
      return Center(child: GameLoadingIndicator(label: l10n.loading));
    }

    if (_errorMessage != null) {
      return GameAsyncStatePanel(
        message: _errorMessage!,
        isError: true,
        onRetry: _loadLeaderboard,
        retryLabel: l10n.retry,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          if (!widget.isEmbedded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  GameBackButton(
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: GameButtonLabel(
                        l10n.leaderboardTitle,
                        fontSize: 20,
                        color: AppColors.woodDeep,
                        outlineColor: AppColors.authCard,
                        outlineWidth: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          if (_myRank != null && _myRank! > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade300, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const AppIcon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.leaderboardYourRank(_myRank!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final frame in [
                            {'id': 'daily', 'label': l10n.leaderboardToday},
                            {'id': 'weekly', 'label': l10n.leaderboardThisWeek},
                            {
                              'id': 'monthly',
                              'label': l10n.leaderboardThisMonth,
                            },
                          ])
                            _buildFilterChip(
                              label: frame['label'] as String,
                              active: _timeFrame == frame['id'],
                              onTap: () {
                                setState(
                                  () => _timeFrame = frame['id'] as String,
                                );
                                _loadLeaderboard();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricDropdown(l10n)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (top3.isNotEmpty) _buildPodium(top3, colorScheme),
                if (rest.isNotEmpty)
                  ...rest.asMap().entries.map(
                    (entry) =>
                        _buildRankCard(entry.value, entry.key + 4, colorScheme),
                  ),
                if (_isMeOutsideTop10) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  _buildRankCard(
                    sortedUsers[_myIndex],
                    _myIndex + 1,
                    colorScheme,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<_UserRank> top3, ColorScheme colorScheme) {
    final top1 = top3[0];
    final top2 = top3.length > 1 ? top3[1] : null;
    final top3User = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumCard(
              rank: 2,
              user: top2,
              height: 96,
              color: Colors.blueGrey.shade400,
              accentColor: Colors.blueGrey.shade700,
              colorScheme: colorScheme,
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildPodiumCard(
              rank: 1,
              user: top1,
              height: 120,
              color: Colors.amber.shade400,
              accentColor: Colors.amber.shade700,
              colorScheme: colorScheme,
            ),
          ),
          Expanded(
            child: _buildPodiumCard(
              rank: 3,
              user: top3User,
              height: 76,
              color: Colors.orange.shade800,
              accentColor: Colors.orange.shade900,
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard({
    required int rank,
    required _UserRank? user,
    required double height,
    required Color color,
    required Color accentColor,
    required ColorScheme colorScheme,
  }) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    final value = _metric == 'level'
        ? 'Lv.${user.level}'
        : _formatNumber(user.steps[_timeFrame]!);

    final displayName = user.isMe
        ? AppLocalizations.of(context).leaderboardYou
        : user.name;

    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: user.isMe ? Colors.white : colorScheme.surface,
          child: Text(
            displayName.substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: user.isMe ? accentColor : colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankCard(_UserRank user, int rank, ColorScheme colorScheme) {
    final isMe = user.isMe;
    final value = _metric == 'level'
        ? 'Lv.${user.level}'
        : _formatNumber(user.steps[_timeFrame]!);
    final l10n = AppLocalizations.of(context);
    final displayName = isMe ? l10n.leaderboardYou : user.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: user.isMe || user.id.isEmpty
            ? null
            : () => Navigator.pushNamed(
                context,
                '/profile/friend',
                arguments: FriendPlayerProfileArguments(
                  userId: user.id,
                  initialName: user.name,
                ),
              ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.amber.shade50 : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMe ? Colors.amber.shade400 : colorScheme.outlineVariant,
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isMe
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: isMe
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  displayName.substring(0, 1),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isMe ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isMe
                            ? Colors.amber.shade800
                            : colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.levelShort(user.level),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _metric == 'level' ? l10n.leaderboardLevel : l10n.step,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}

class _UserRank {
  final String id;
  final String name;
  final Map<String, int> steps;
  final int level;
  final bool isMe;
  final bool isFriend;
  final int rank;

  const _UserRank({
    required this.id,
    required this.name,
    required this.steps,
    required this.level,
    required this.isMe,
    required this.isFriend,
    this.rank = 0,
  });
}
