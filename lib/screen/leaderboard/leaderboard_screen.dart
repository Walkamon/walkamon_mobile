import 'package:flutter/material.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../l10n/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isEmbedded;

  const LeaderboardScreen({super.key, this.isEmbedded = false});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardRepository _repository = LeaderboardRepository();

  String _scope = 'global';
  String _timeFrame = 'daily';
  String _metric = 'steps';
  bool _isLoading = true;
  String? _errorMessage;
  List<_UserRank> _users = [];
  int? _myRank;

  @override
  void initState() {
    super.initState();
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
                  id: item.userId.hashCode,
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final sortedUsers = _sortedUsers;
    final top3 = _top3;
    final rest = _rest;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, widget.isEmbedded ? 8 : 20, 20, 0),
      child: Column(
        children: [
          if (!widget.isEmbedded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.leaderboardTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
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
                  const Icon(
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
                    Expanded(
                      child: _buildDropdown(
                        label: _metric == 'steps'
                            ? l10n.leaderboardSteps
                            : l10n.leaderboardLevel,
                        selectedValue: _metric,
                        items: [
                          {'value': 'steps', 'label': l10n.leaderboardSteps},
                          {'value': 'level', 'label': l10n.leaderboardLevel},
                        ],
                        onChanged: (value) {
                          setState(() => _metric = value!);
                        },
                      ),
                    ),
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

  Widget _buildDropdown({
    required String label,
    required String selectedValue,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(
                    item['label']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          borderRadius: BorderRadius.circular(12),
          hint: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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

    return Container(
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
                    color: isMe ? Colors.amber.shade800 : colorScheme.onSurface,
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
  final int id;
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
