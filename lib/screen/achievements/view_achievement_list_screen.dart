import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/remote/achievement_screen_datasource.dart';
import '../../data/models/achievement_response.dart';
import '../../data/repositories/achievement_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/game_notification_dialog.dart';

class ViewAchievementListScreen extends StatefulWidget {
  const ViewAchievementListScreen({super.key, this.repository});

  final AchievementScreenRepository? repository;

  @override
  State<ViewAchievementListScreen> createState() =>
      _ViewAchievementListScreenState();
}

class _ViewAchievementListScreenState extends State<ViewAchievementListScreen> {
  String _activeTab = 'unlocked';
  Map<String, dynamic>? _selectedAchievement;
  bool _isLoading = true;
  String? _errorMessage;
  List<AchievementResponse> _achievements = [];
  String? _claimingAchievementId;

  late final AchievementScreenRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        AchievementScreenRepository(AchievementScreenDatasource(ApiClient()));
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final data = await _repository.getAchievements();
      if (!mounted) return;
      setState(() {
        _achievements = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClaim(String achievementId) async {
    setState(() => _claimingAchievementId = achievementId);
    try {
      final result = await _repository.claimAchievement(achievementId);
      final provider = context.read<GameStateProvider>();
      final user = provider.user;
      if (user != null) {
        provider.setUser(user.copyWith(coins: result.walletBalance));
      }

      if (mounted) {
        showGameNotificationDialog(
          context,
          message: 'Nhận thành công: +${result.walletAmount}',
          isSuccess: true,
        );
      }
      await _loadAchievements();
    } catch (e) {
      if (mounted) {
        showGameNotificationDialog(
          context,
          message: 'Không thể nhận thưởng: $e',
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _claimingAchievementId = null);
      if (mounted) setState(() => _selectedAchievement = null);
    }
  }

  List<AchievementResponse> get _claimedAchievements =>
      _achievements.where((item) => item.claimedAt != null).toList();

  List<AchievementResponse> get _unclaimedAchievements {
    final list = _achievements.where((item) => item.claimedAt == null).toList();
    list.sort((a, b) {
      final aClaimable =
          a.canClaim || (a.targetValue > 0 && a.progressValue >= a.targetValue);
      final bClaimable =
          b.canClaim || (b.targetValue > 0 && b.progressValue >= b.targetValue);
      if (aClaimable && !bClaimable) return -1;
      if (!aClaimable && bClaimable) return 1;
      // If both same claimability, put the one with higher progress first
      final aProgressRatio = a.targetValue > 0
          ? a.progressValue / a.targetValue
          : 0.0;
      final bProgressRatio = b.targetValue > 0
          ? b.progressValue / b.targetValue
          : 0.0;
      return bProgressRatio.compareTo(aProgressRatio);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const AppIcon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.achievementVault,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: l10n.achievementsUnlockedTab,
                            selected: _activeTab == 'unlocked',
                            onTap: () =>
                                setState(() => _activeTab = 'unlocked'),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: l10n.achievementsLockedTab,
                            selected: _activeTab == 'locked',
                            onTap: () => setState(() => _activeTab = 'locked'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          )
                        : _activeTab == 'unlocked'
                        ? _buildUnlockedView(theme)
                        : _buildLockedView(theme, isDark),
                  ),
                ],
              ),
            ),
            if (_selectedAchievement != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAchievement = null),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Material(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: () => setState(
                                        () => _selectedAchievement = null,
                                      ),
                                      icon: const AppIcon(Icons.close_rounded),
                                    ),
                                  ),
                                  if (_selectedAchievement!['isLocked']
                                      as bool) ...[
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey.shade200,
                                      child: const AppIcon(
                                        Icons.lock_rounded,
                                        size: 34,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedAchievement!['title'],
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.achievementsCurrentProgress,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value:
                                                (_selectedAchievement!['progress'] /
                                                        _selectedAchievement!['target'])
                                                    .clamp(0.0, 1.0),
                                            minHeight: 8,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_formatCompact(_selectedAchievement!['progress'])}/${_formatCompact(_selectedAchievement!['target'])}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.achievementsLockedDetail(
                                        _selectedAchievement!['desc'],
                                        _selectedAchievement!['reward'],
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ] else ...[
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          theme.colorScheme.surfaceVariant,
                                      child:
                                          _selectedAchievement!['iconUrl'] !=
                                                  null &&
                                              (_selectedAchievement!['iconUrl']
                                                      as String)
                                                  .isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Image.network(
                                                _selectedAchievement!['iconUrl'],
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const AppIcon(
                                                      Icons
                                                          .emoji_events_rounded,
                                                    ),
                                              ),
                                            )
                                          : const AppIcon(
                                              Icons.emoji_events_rounded,
                                              size: 34,
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedAchievement!['title'],
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.achievementsUnlockedAt(
                                        _selectedAchievement!['date'],
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.achievementsUnlockedDetail(
                                        _selectedAchievement!['desc'],
                                      ),
                                      style: theme.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Builder(
                                      builder: (context) {
                                        final isLocked =
                                            _selectedAchievement!['isLocked']
                                                as bool;
                                        final achId =
                                            _selectedAchievement!['achievementId']
                                                as String?;
                                        final canClaim =
                                            _selectedAchievement!['canClaim']
                                                as bool? ??
                                            false;
                                        final claimedAt =
                                            (_selectedAchievement!['claimedAt']
                                                    as String?)
                                                ?.toString() ??
                                            '';
                                        final isClaimed = claimedAt.isNotEmpty;
                                        final progress =
                                            int.tryParse(
                                              _selectedAchievement!['progress']
                                                      ?.toString() ??
                                                  '',
                                            ) ??
                                            0;
                                        final target =
                                            int.tryParse(
                                              _selectedAchievement!['target']
                                                      ?.toString() ??
                                                  '',
                                            ) ??
                                            0;
                                        final completed =
                                            target > 0 && progress >= target;
                                        final canClaimComputed =
                                            canClaim || completed;

                                        return ElevatedButton(
                                          onPressed: isLocked
                                              ? () => setState(
                                                  () => _selectedAchievement =
                                                      null,
                                                )
                                              : (achId != null &&
                                                    canClaimComputed)
                                              ? () => _handleClaim(achId)
                                              : () => setState(
                                                  () => _selectedAchievement =
                                                      null,
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor:
                                                theme.colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                          child:
                                              _claimingAchievementId != null &&
                                                  _claimingAchievementId ==
                                                      achId
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  isLocked
                                                      ? l10n.achievementsKeepTrying
                                                      : (isClaimed
                                                            ? l10n.dailyLoginSuccessAction
                                                            : (canClaimComputed
                                                                  ? l10n.dailyLoginClaimNow
                                                                  : l10n.achievementsKeepTrying)),
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedView(ThemeData theme) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFFFF8E1),
                child: const AppIcon(
                  Icons.emoji_events_rounded,
                  size: 34,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).achievementsCollection,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(
                  context,
                ).achievementsCollected(_claimedAchievements.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _claimedAchievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final item = _claimedAchievements[index];
            return InkWell(
              onTap: () => setState(
                () => _selectedAchievement = {
                  'achievementId': item.achievementId,
                  'title': item.title,
                  'desc': item.description,
                  'iconUrl': item.iconUrl,
                  'isLocked': false,
                  'canClaim': item.canClaim,
                  'date': item.unlockedAt ?? '',
                  'claimedAt': item.claimedAt ?? '',
                },
              ),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      child: item.iconUrl != null && item.iconUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Image.network(
                                item.iconUrl!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const AppIcon(Icons.emoji_events_rounded),
                              ),
                            )
                          : const AppIcon(Icons.emoji_events_rounded, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLockedView(ThemeData theme, bool isDark) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade200,
                child: const AppIcon(
                  Icons.lock_rounded,
                  size: 34,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context).achievementsGoals,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(
                  context,
                ).achievementsLockedCount(_unclaimedAchievements.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._unclaimedAchievements.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(
                () => _selectedAchievement = {
                  'achievementId': item.achievementId,
                  'title': item.title,
                  'desc': item.description,
                  'iconUrl': item.iconUrl,
                  'isLocked': !item.isUnlocked,
                  'date': item.unlockedAt ?? '',
                  'claimedAt': item.claimedAt ?? '',
                  'progress': item.progressValue,
                  'target': item.targetValue,
                  'reward': item.walletAmount,
                  'canClaim': item.canClaim,
                },
              ),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                      child: item.isUnlocked
                          ? const AppIcon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                            )
                          : const AppIcon(
                              Icons.lock_rounded,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: Builder(
                                    builder: (context) {
                                      final completed =
                                          item.targetValue > 0 &&
                                          item.progressValue >=
                                              item.targetValue;
                                      final progressValue = item.targetValue > 0
                                          ? item.progressValue /
                                                item.targetValue
                                          : 0.0;
                                      final activeColor = completed
                                          ? theme.colorScheme.primary
                                          : (isDark
                                                ? Colors.grey.shade700
                                                : Colors.grey.shade300);

                                      return LinearProgressIndicator(
                                        value: progressValue.clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200,
                                        color: activeColor,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatCompact(item.progressValue)}/${_formatCompact(item.targetValue)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
