import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/remote/achievement_screen_datasource.dart';
import '../../data/models/achievement_response.dart';
import '../../data/repositories/achievement_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/game_notification_dialog.dart';
import '../../widgets/common/game_dual_bottom_tabs.dart';

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
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _selectedAchievement == null
          ? GameDualBottomTabs(
              firstLabel: l10n.achievementsUnlockedTab,
              secondLabel: l10n.achievementsLockedTab,
              firstSelected: _activeTab == 'unlocked',
              onFirstTap: () => setState(() => _activeTab = 'unlocked'),
              onSecondTap: () => setState(() => _activeTab = 'locked'),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      GameBackButton(
                        semanticLabel: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: GameButtonLabel(
                            l10n.achievementVault,
                            fontSize: 20,
                            color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
                            outlineColor: isDark ? AppColors.darkTextOutline : AppColors.authCard,
                            outlineWidth: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.authCard.withValues(alpha: 0.97),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.wood,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                          color: AppColors.authCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(
                              color: AppColors.wood,
                              width: 2,
                            ),
                          ),
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
                                      icon: const AppIcon(
                                        Icons.close_rounded,
                                        size: 28,
                                        color: AppColors.woodDeep,
                                      ),
                                    ),
                                  ),
                                  if (_selectedAchievement!['isLocked']
                                      as bool) ...[
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.parchment,
                                      child: const AppIcon(
                                        Icons.lock_rounded,
                                        size: 34,
                                        color: AppColors.outlineBrown,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedAchievement!['title'],
                                      style: const TextStyle(
                                        color: AppColors.woodDeep,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.creamLight,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.wood,
                                          width: 1.4,
                                        ),
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
                                                  color: AppColors.woodDeep,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value:
                                                (_selectedAchievement!['progress'] /
                                                        _selectedAchievement!['target'])
                                                    .clamp(0.0, 1.0),
                                            minHeight: 8,
                                            backgroundColor:
                                                AppColors.parchment,
                                            color: AppColors.buttonGreen,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${_formatCompact(_selectedAchievement!['progress'])}/${_formatCompact(_selectedAchievement!['target'])}',
                                            style: const TextStyle(
                                              color: AppColors.outlineBrown,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
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
                                      style: const TextStyle(
                                        color: AppColors.outlineBrown,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ] else ...[
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.creamLight,
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
                                      style: const TextStyle(
                                        color: AppColors.woodDeep,
                                        fontSize: 20,
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
                                            color: AppColors.outlineBrown,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.achievementsUnlockedDetail(
                                        _selectedAchievement!['desc'],
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.outlineBrown,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                            backgroundColor: isDark
                                                ? AppColors.darkLife
                                                : AppColors.buttonGreen,
                                            foregroundColor: isDark
                                                ? AppColors.darkTextOutline
                                                : AppColors.buttonText,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: StadiumBorder(
                                              side: BorderSide(
                                                color: isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.woodDeep,
                                                width: 2,
                                              ),
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
                                              : GameButtonLabel(
                                                  isLocked
                                                      ? l10n.achievementsKeepTrying
                                                      : (isClaimed
                                                            ? l10n.dailyLoginSuccessAction
                                                            : (canClaimComputed
                                                                  ? l10n.dailyLoginClaimNow
                                                                  : l10n.achievementsKeepTrying)),
                                                  fontSize: 14,
                                                  color: AppColors.buttonText,
                                                  outlineColor:
                                                      AppColors.woodDeep,
                                                  outlineWidth: 2.5,
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
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slotCount = _claimedAchievements.length < 20
        ? 20
        : _claimedAchievements.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNestedCard : AppColors.authCard.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.wood, width: 2),
          ),
          child: Column(
            children: [
              const AppIcon(
                Icons.emoji_events_rounded,
                asset: null,
                size: 42,
                color: AppColors.gold,
              ),
              const SizedBox(height: 6),
              GameButtonLabel(
                l10n.achievementsCollection,
                fontSize: 19,
                color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
                outlineColor: isDark ? AppColors.darkTextOutline : AppColors.authCard,
                outlineWidth: 3,
              ),
              const SizedBox(height: 3),
              Text(
                l10n.achievementsCollected(_claimedAchievements.length),
                style: TextStyle(
                  color: isDark ? AppColors.darkMutedForeground : AppColors.outlineBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkMuted : AppColors.leafLight.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.oliveDeep, width: 2),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slotCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final hasItem = index < _claimedAchievements.length;
              final item = hasItem ? _claimedAchievements[index] : null;
              return Material(
                color: (isDark ? AppColors.darkNestedCard : AppColors.authCard).withValues(
                  alpha: hasItem ? 0.97 : 0.55,
                ),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: item == null
                      ? null
                      : () => setState(
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
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasItem
                            ? (isDark ? AppColors.darkBorder : AppColors.wood)
                            : (isDark ? AppColors.darkBorder.withValues(alpha: 0.38) : AppColors.wood.withValues(alpha: 0.38)),
                        width: hasItem ? 1.5 : 1,
                      ),
                    ),
                    child: item == null
                        ? const SizedBox.expand()
                        : (item.iconUrl?.isNotEmpty == true
                              ? Image.network(
                                  item.iconUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const AppIcon(
                                    Icons.emoji_events_rounded,
                                    size: 38,
                                    color: AppColors.gold,
                                  ),
                                )
                              : const AppIcon(
                                  Icons.emoji_events_rounded,
                                  size: 38,
                                  color: AppColors.gold,
                                )),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLockedView(ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context);
    final list = _unclaimedAchievements;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkMuted : AppColors.leafLight.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.oliveDeep, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDeep.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 40, 12, 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkNestedCard : AppColors.authCard.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.wood, width: 1.5),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final completed =
                      item.targetValue > 0 &&
                      item.progressValue >= item.targetValue;
                  final progressValue = item.targetValue > 0
                      ? item.progressValue / item.targetValue
                      : 0.0;
                  return InkWell(
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
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppColors.leafLight.withValues(alpha: 0.72)
                            : AppColors.authCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: completed
                              ? AppColors.oliveDeep
                              : AppColors.wood,
                          width: 1.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.creamLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.wood,
                                width: 1.3,
                              ),
                            ),
                            child:
                                item.isUnlocked &&
                                    item.iconUrl?.isNotEmpty == true
                                ? Image.network(
                                    item.iconUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const AppIcon(
                                      Icons.emoji_events_rounded,
                                      color: AppColors.gold,
                                    ),
                                  )
                                : AppIcon(
                                    item.isUnlocked
                                        ? Icons.emoji_events_rounded
                                        : Icons.star_border_rounded,
                                    color: item.isUnlocked
                                        ? AppColors.gold
                                        : AppColors.woodLight,
                                    size: 28,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.inkDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.outlineBrown,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: progressValue.clamp(0.0, 1.0),
                                          minHeight: 8,
                                          backgroundColor: AppColors.parchment,
                                          color: completed
                                              ? AppColors.buttonGreen
                                              : AppColors.goldLight,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_formatCompact(item.progressValue)}/${_formatCompact(item.targetValue)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.outlineBrown,
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
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 44,
          right: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.woodLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.woodDeep, width: 2),
            ),
            child: GameButtonLabel(
              l10n.achievementsGoals,
              fontSize: 15,
              color: AppColors.buttonText,
              outlineColor: AppColors.woodDeep,
              outlineWidth: 2.5,
            ),
          ),
        ),
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
