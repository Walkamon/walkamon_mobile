import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/localization/translation_resolver.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/audio/app_audio_service.dart';
import '../../core/localization/game_content_localizer.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/player_challenge_response.dart';
import '../../data/models/player_mission_response.dart';
import '../../data/repositories/missions_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/asset_only_icon_button.dart';
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_notification_dialog.dart';
import '../../widgets/common/game_async_state.dart';

enum MissionTab { mission, challenge }

enum MissionListTab { daily, overall }

class _QuestDisplayItem {
  const _QuestDisplayItem({
    required this.missionId,
    this.userMissionId,
    required this.title,
    required this.description,
    required this.target,
    required this.current,
    required this.reward,
    required this.isChallenge,
    required this.canClaim,
    required this.isClaimed,
    required this.isCancelable,
  });

  final String missionId;
  final String? userMissionId;
  final String title;
  final String description;
  final int target;
  final int current;
  final int reward;
  final bool isChallenge;
  final bool canClaim;
  final bool isClaimed;
  final bool isCancelable;

  bool get isCompleted =>
      isClaimed || canClaim || (target > 0 && current >= target);
}

class DewdropIcon extends StatelessWidget {
  const DewdropIcon({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DewdropPainter(color: color ?? AppColors.lightDew),
    );
  }
}

class _DewdropPainter extends CustomPainter {
  _DewdropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.104)
      ..cubicTo(
        size.width * 0.8125,
        size.height * 0.395,
        size.width * 0.8125,
        size.height * 0.583,
        size.width * 0.5,
        size.height * 0.896,
      )
      ..cubicTo(
        size.width * 0.1875,
        size.height * 0.583,
        size.width * 0.1875,
        size.height * 0.395,
        size.width * 0.5,
        size.height * 0.104,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DewdropPainter oldDelegate) =>
      oldDelegate.color != color;
}

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final MissionsScreenRepository _repository = MissionsScreenRepository();

  MissionTab _activeTab = MissionTab.mission;
  MissionListTab _activeMissionListTab = MissionListTab.daily;
  bool _isLoading = true;
  String? _errorMessage;

  List<_QuestDisplayItem> _dailyQuests = [];
  List<_QuestDisplayItem> _overallQuests = [];
  List<_QuestDisplayItem> _challengeQuests = [];

  int _cancelLimit = 3;
  int _cancelRemaining = 3;

  String? _claimingMissionId;
  String? _creatingChallenge;
  String? _cancellingChallengeId;
  Locale? _contentLocale;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextLocale = Localizations.localeOf(context);
    final previousLocale = _contentLocale;
    _contentLocale = nextLocale;
    if (previousLocale != null && previousLocale != nextLocale && !_isLoading) {
      unawaited(_loadData());
    }
  }

  _QuestDisplayItem _fromMission(
    PlayerMissionItemResponse mission,
    AppLocalizations l10n,
  ) {
    final claimed = mission.statusCode.toLowerCase() == 'claimed';
    final fallbackDescription = mission.description?.trim().isNotEmpty == true
        ? mission.description!.trim()
        : l10n.missionsDefaultDescription;
    return _QuestDisplayItem(
      missionId: mission.missionId,
      userMissionId: mission.userMissionId,
      title: GameContentLocalizer.questTitle(
        context,
        metricCode: mission.metricCode,
        targetValue: mission.targetValue,
        fallback: mission.title,
      ),
      description: GameContentLocalizer.questDescription(
        context,
        metricCode: mission.metricCode,
        targetValue: mission.targetValue,
        fallback: fallbackDescription,
      ),
      target: mission.targetValue,
      current: mission.progressValue,
      reward: mission.walletAmount,
      isChallenge: false,
      canClaim: mission.canClaim,
      isClaimed: claimed,
      isCancelable: false,
    );
  }

  _QuestDisplayItem _fromChallenge(
    PlayerChallengeResponse challenge,
    AppLocalizations l10n,
  ) {
    final claimed = challenge.statusCode.toLowerCase() == 'claimed';
    final completed = challenge.progressValue >= challenge.targetValue;
    final fallbackDescription = challenge.description?.trim().isNotEmpty == true
        ? challenge.description!.trim()
        : l10n.missionsChallengeDescription;

    return _QuestDisplayItem(
      missionId: challenge.challengeId,
      userMissionId: challenge.userMissionId,
      title: GameContentLocalizer.questTitle(
        context,
        metricCode: challenge.metricCode,
        targetValue: challenge.targetValue,
        fallback: challenge.title,
      ),
      description: GameContentLocalizer.questDescription(
        context,
        metricCode: challenge.metricCode,
        targetValue: challenge.targetValue,
        fallback: fallbackDescription,
      ),
      target: challenge.targetValue,
      current: challenge.progressValue,
      reward: challenge.walletAmount,
      isChallenge: true,
      canClaim: completed && !claimed,
      isClaimed: claimed,
      isCancelable: challenge.isCancelable,
    );
  }

  List<_QuestDisplayItem> _prioritizeCompletedQuests(
    Iterable<_QuestDisplayItem> quests,
  ) {
    final indexedQuests = quests.toList().asMap().entries.toList();

    int priority(_QuestDisplayItem quest) {
      if (quest.canClaim && !quest.isClaimed) return 0;
      if (quest.isCompleted && !quest.isClaimed) return 1;
      if (!quest.isClaimed) return 2;
      return 3;
    }

    indexedQuests.sort((a, b) {
      final priorityComparison = priority(a.value).compareTo(priority(b.value));
      return priorityComparison != 0
          ? priorityComparison
          : a.key.compareTo(b.key);
    });

    return indexedQuests.map((entry) => entry.value).toList();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final missionsFuture = _repository.getAllMissions();
      final challengeFuture = _repository.getChallengeState();
      final results = await Future.wait([missionsFuture, challengeFuture]);
      final missions = results[0] as PlayerMissionListResponse;
      final challengeState = results[1] as PlayerChallengeStateResponse;

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _dailyQuests = _prioritizeCompletedQuests(
          missions.dailyMissions.map((mission) => _fromMission(mission, l10n)),
        );
        _overallQuests = _prioritizeCompletedQuests(
          missions.overallMissions.map(
            (mission) => _fromMission(mission, l10n),
          ),
        );
        _challengeQuests = challengeState.currentChallenge != null
            ? [_fromChallenge(challengeState.currentChallenge!, l10n)]
            : [];
        _cancelLimit = challengeState.cancelLimit;
        _cancelRemaining = challengeState.cancelRemaining;
        if (showLoading) _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dailyQuests = [];
        _overallQuests = [];
        _challengeQuests = [];
        _errorMessage = AppLocalizations.of(context).missionsLoadError;
        if (showLoading) _isLoading = false;
      });
    }
  }

  Future<void> _handleClaim(_QuestDisplayItem quest) async {
    // Handle mission claim
    if (!quest.isChallenge) {
      if (!quest.canClaim) return;

      AppAudioService.instance.suppressNextTabSound();
      setState(() => _claimingMissionId = quest.missionId);
      final provider = context.read<GameStateProvider>();
      try {
        final result = await _repository.claimMission(quest.missionId);
        final user = provider.user;
        if (user != null) {
          provider.setUser(user.copyWith(coins: result.walletBalance));
        }

        unawaited(AppAudioService.instance.playReward());

        if (mounted) {
          _showReward(
            AppLocalizations.of(
              context,
            ).missionsClaimSuccess(result.walletAmount),
          );
        }
        await _loadData(showLoading: false);
      } catch (e) {
        if (mounted) {
          _showError(AppLocalizations.of(context).missionsClaimFailed('$e'));
        }
      } finally {
        if (mounted) setState(() => _claimingMissionId = null);
      }
      return;
    }

    // Handle challenge claim
    if (quest.userMissionId == null || quest.userMissionId!.isEmpty) return;

    AppAudioService.instance.suppressNextTabSound();
    setState(() => _claimingMissionId = quest.missionId);
    final provider = context.read<GameStateProvider>();
    try {
      final result = await _repository.claimChallenge(quest.userMissionId!);
      final user = provider.user;
      if (user != null) {
        provider.setUser(user.copyWith(coins: result.walletBalance));
      }

      unawaited(AppAudioService.instance.playReward());

      if (mounted) {
        _showReward(
          AppLocalizations.of(
            context,
          ).missionsClaimSuccess(result.walletAmount),
        );
      }
      await _loadData(showLoading: false);
    } catch (e) {
      if (mounted) {
        _showError(TranslationResolver.resolveError(context, e));
      }
    } finally {
      if (mounted) setState(() => _claimingMissionId = null);
    }
  }

  Future<void> _handleRandomChallenge() async {
    if (_challengeQuests.isNotEmpty) {
      _showError(AppLocalizations.of(context).missionsChallengeExists);
      return;
    }

    setState(() => _creatingChallenge = 'loading');
    try {
      final resp = await _repository.createRandomChallenge();
      if (resp.success && resp.data != null) {
        if (mounted) {
          setState(() {
            _challengeQuests = resp.data!.currentChallenge != null
                ? [
                    _fromChallenge(
                      resp.data!.currentChallenge!,
                      AppLocalizations.of(context),
                    ),
                  ]
                : [];
            _cancelLimit = resp.data!.cancelLimit;
            _cancelRemaining = resp.data!.cancelRemaining;
          });
          _showSuccess(AppLocalizations.of(context).missionsChallengeCreated);
        }
      } else {
        _showError(TranslationResolver.resolveResponse(context, resp));
      }
    } catch (e) {
      _showError(TranslationResolver.resolveError(context, e));
      if (mounted) {
        await _refreshChallengeState();
      }
    } finally {
      if (mounted) setState(() => _creatingChallenge = null);
    }
  }

  Future<void> _refreshChallengeState() async {
    try {
      final challengeState = await _repository.getChallengeState();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _challengeQuests = challengeState.currentChallenge != null
            ? [_fromChallenge(challengeState.currentChallenge!, l10n)]
            : [];
        _cancelLimit = challengeState.cancelLimit;
        _cancelRemaining = challengeState.cancelRemaining;
      });
    } catch (_) {
      // Ignore refresh failures; keep existing UI state.
    }
  }

  Future<void> _handleCancelChallenge(_QuestDisplayItem quest) async {
    if (_cancelRemaining <= 0 || quest.userMissionId == null) return;

    setState(() => _cancellingChallengeId = quest.userMissionId);
    try {
      final resp = await _repository.cancelChallenge(quest.userMissionId!);
      if (resp.success && resp.data != null) {
        if (mounted) {
          setState(() {
            _challengeQuests = [];
            _cancelRemaining = resp.data!.cancelRemaining;
            _cancelLimit = resp.data!.cancelLimit;
          });
        }
        if (mounted) {
          setState(() {
            _challengeQuests = [];
            _cancelRemaining = resp.data!.cancelRemaining;
            _cancelLimit = resp.data!.cancelLimit;
          });
        }
        _showMessage(AppLocalizations.of(context).missionsChallengeCanceled);
        if (mounted) {
          await _refreshChallengeState();
        }
      } else {
        _showError(TranslationResolver.resolveResponse(context, resp));
        if (mounted) {
          await _refreshChallengeState();
        }
      }
    } catch (e) {
      _showError(TranslationResolver.resolveError(context, e));
      if (mounted) {
        await _refreshChallengeState();
      }
    } finally {
      if (mounted) setState(() => _cancellingChallengeId = null);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showGameNotificationDialog(context, message: message, isSuccess: true);
  }

  void _showError(String message) {
    if (!mounted) return;
    showGameNotificationDialog(context, message: message, isSuccess: false);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showGameNotificationDialog(context, message: message, isSuccess: true);
  }

  void _showReward(String message) {
    if (!mounted) return;
    showGameNotificationDialog(
      context,
      message: message,
      isSuccess: true,
      isReward: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    // Completed/claim actions use the warm wood/gold palette in dark mode so
    // they remain readable and consistent with the inventory title treatment.
    final accent = isDark ? AppColors.darkBorder : AppColors.lightAccent;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final dewColor = isDark ? AppColors.darkDew : AppColors.lightDew;
    final energyColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final visibleMissionQuests = _activeMissionListTab == MissionListTab.daily
        ? _dailyQuests
        : _overallQuests;
    final visibleMissionEmptyMessage =
        _activeMissionListTab == MissionListTab.daily
        ? l10n.missionsDailyEmpty
        : l10n.missionsOverallEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: _MissionTabs(
          missionLabel: l10n.missionsTabMission,
          challengeLabel: l10n.missionsTabChallenge,
          activeTab: _activeTab,
          cardColor: cardColor,
          borderColor: borderColor,
          foreground: foreground,
          mutedForeground: mutedForeground,
          onChanged: (tab) {
            if (tab == _activeTab) return;
            setState(() => _activeTab = tab);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              children: [
                _MissionsHeader(
                  title: l10n.missionsTitle,
                  onBack: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? Center(child: GameLoadingIndicator(label: l10n.loading))
                : _errorMessage != null &&
                      _dailyQuests.isEmpty &&
                      _overallQuests.isEmpty &&
                      _challengeQuests.isEmpty
                ? GameAsyncStatePanel(
                    message: _errorMessage!,
                    isError: true,
                    onRetry: _loadData,
                    retryLabel: l10n.retry,
                  )
                : LayoutBuilder(
                    builder: (context, contentConstraints) {
                      final missionPanelHeight =
                          (contentConstraints.maxHeight - 36).clamp(
                            0.0,
                            contentConstraints.maxHeight,
                          );
                      return RefreshIndicator(
                        onRefresh: _loadData,
                        notificationPredicate: (notification) =>
                            notification.depth ==
                            (_activeTab == MissionTab.mission ? 1 : 0),
                        child: ListView(
                          physics: _activeTab == MissionTab.mission
                              ? const NeverScrollableScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          children: [
                            if (_activeTab == MissionTab.mission) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: missionPanelHeight,
                                child: _MissionListPanel(
                                  tabs: _MissionListTabs(
                                    dailyLabel: l10n.missionsDailyTitle,
                                    overallLabel: l10n.missionsOverallTitle,
                                    activeTab: _activeMissionListTab,
                                    onChanged: (tab) {
                                      if (tab == _activeMissionListTab) return;
                                      setState(
                                        () => _activeMissionListTab = tab,
                                      );
                                    },
                                  ),
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    children: visibleMissionQuests.isEmpty
                                        ? [
                                            _EmptySection(
                                              message:
                                                  visibleMissionEmptyMessage,
                                              mutedForeground: mutedForeground,
                                            ),
                                          ]
                                        : visibleMissionQuests
                                              .asMap()
                                              .entries
                                              .map(
                                                (entry) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 10,
                                                      ),
                                                  child: _QuestItemCard(
                                                    quest: entry.value,
                                                    index: entry.key,
                                                    cardColor: cardColor,
                                                    borderColor: borderColor,
                                                    foreground: foreground,
                                                    mutedForeground:
                                                        mutedForeground,
                                                    accent: accent,
                                                    muted: muted,
                                                    dewColor: dewColor,
                                                    energyColor: energyColor,
                                                    isClaimLoading:
                                                        _claimingMissionId ==
                                                        entry.value.missionId,
                                                    cancelRemaining:
                                                        _cancelRemaining,
                                                    isCancelLoading:
                                                        _cancellingChallengeId ==
                                                        entry
                                                            .value
                                                            .userMissionId,
                                                    onClaim: () => _handleClaim(
                                                      entry.value,
                                                    ),
                                                    onCancel: () =>
                                                        _handleCancelChallenge(
                                                          entry.value,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: GameButtonLabel(
                                        l10n.missionsRandomChallenge,
                                        fontSize: 15,
                                        color: AppColors.woodDeep,
                                        outlineColor: AppColors.authCard,
                                        outlineWidth: 3.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: GameButtonLabel(
                                      l10n.missionsCancelRemaining(
                                        _cancelRemaining,
                                        _cancelLimit,
                                      ),
                                      fontSize: 12,
                                      color: _cancelRemaining <= 0
                                          ? Theme.of(context).colorScheme.error
                                          : AppColors.oliveDeep,
                                      outlineColor: AppColors.authCard,
                                      outlineWidth: 3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_challengeQuests.isEmpty)
                                Material(
                                  color: AppColors.authCard.withValues(
                                    alpha: 0.94,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    onTap: _creatingChallenge != null
                                        ? null
                                        : _handleRandomChallenge,
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: double.infinity,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppColors.wood,
                                          width: 2,
                                        ),
                                      ),
                                      child: _creatingChallenge != null
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                AppIcon(
                                                  Icons.shuffle,
                                                  asset:
                                                      AppAssets.iconChallenge,
                                                  size: 38,
                                                ),
                                                const SizedBox(width: 12),
                                                GameButtonLabel(
                                                  l10n.missionsNewChallenge,
                                                  fontSize: 15,
                                                  color: AppColors.woodDeep,
                                                  outlineColor: AppColors.ivory,
                                                  outlineWidth: 2.5,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              if (_challengeQuests.isEmpty) ...[
                                const SizedBox(height: 24),
                                Center(
                                  child: GameButtonLabel(
                                    l10n.missionsNoActiveChallenge,
                                    fontSize: 13,
                                    color: AppColors.oliveDeep,
                                    outlineColor: AppColors.authCard,
                                    outlineWidth: 3,
                                  ),
                                ),
                              ] else
                                ..._challengeQuests.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _QuestItemCard(
                                      quest: entry.value,
                                      index: entry.key,
                                      cardColor: cardColor,
                                      borderColor: borderColor,
                                      foreground: foreground,
                                      mutedForeground: mutedForeground,
                                      accent: accent,
                                      muted: muted,
                                      dewColor: dewColor,
                                      energyColor: energyColor,
                                      isClaimLoading:
                                          _claimingMissionId ==
                                          entry.value.missionId,
                                      cancelRemaining: _cancelRemaining,
                                      isCancelLoading:
                                          _cancellingChallengeId ==
                                          entry.value.userMissionId,
                                      onClaim: () => _handleClaim(entry.value),
                                      onCancel: () =>
                                          _handleCancelChallenge(entry.value),
                                    ),
                                  ),
                                ),
                            ],
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

class _MissionsHeader extends StatelessWidget {
  const _MissionsHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AssetOnlyIconButton(
            onPressed: onBack,
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icons.chevron_left,
            buttonSize: 40,
            assetSize: 34,
          ),
        ),
        GameButtonLabel(
          title,
          fontSize: 20,
          color: AppColors.woodDeep,
          outlineColor: AppColors.authCard,
          outlineWidth: 4,
        ),
      ],
    );
  }
}

class _MissionTabs extends StatelessWidget {
  const _MissionTabs({
    required this.missionLabel,
    required this.challengeLabel,
    required this.activeTab,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    required this.onChanged,
  });

  final String missionLabel;
  final String challengeLabel;
  final MissionTab activeTab;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final ValueChanged<MissionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabCard = isDark ? AppColors.darkCard : AppColors.authCard;
    final tabActive = isDark ? AppColors.woodLight : AppColors.buttonGreen;
    final tabText = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    Widget buildTab(String label, MissionTab tab) {
      final isActive = activeTab == tab;
      return Expanded(
        child: Material(
          color: isActive ? tabActive : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? (isDark ? AppColors.darkBorder : AppColors.woodDeep)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: isActive
                  ? GameButtonLabel(
                      label,
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.buttonText,
                      outlineColor: isDark
                          ? AppColors.darkTextOutline
                          : AppColors.woodDeep,
                      outlineWidth: 2.5,
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tabText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tabCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.wood,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          buildTab(missionLabel, MissionTab.mission),
          const SizedBox(width: 4),
          buildTab(challengeLabel, MissionTab.challenge),
        ],
      ),
    );
  }
}

class _MissionListTabs extends StatelessWidget {
  const _MissionListTabs({
    required this.dailyLabel,
    required this.overallLabel,
    required this.activeTab,
    required this.onChanged,
  });

  final String dailyLabel;
  final String overallLabel;
  final MissionListTab activeTab;
  final ValueChanged<MissionListTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.woodLight : AppColors.woodLight;
    final unselectedColor = isDark ? AppColors.darkCard : AppColors.parchment;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    Widget tab(String label, MissionListTab tab) {
      final selected = activeTab == tab;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? selectedColor : unselectedColor,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isDark
                      ? (selected
                            ? AppColors.darkBorder
                            : AppColors.darkCardBorder)
                      : AppColors.woodDeep,
                  width: selected ? 2 : 1.4,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.24),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? GameButtonLabel(
                      label,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.buttonText,
                      outlineColor: isDark
                          ? AppColors.darkTextOutline
                          : AppColors.woodDeep,
                      outlineWidth: 3,
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          tab(dailyLabel, MissionListTab.daily),
          const SizedBox(width: 4),
          tab(overallLabel, MissionListTab.overall),
        ],
      ),
    );
  }
}

class _MissionListPanel extends StatelessWidget {
  const _MissionListPanel({required this.tabs, required this.child});

  final Widget tabs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkMuted : AppColors.leafLight)
                  .withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.oliveDeep,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDeep.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 42, 12, 4),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCard : AppColors.authCard)
                    .withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.wood,
                  width: 1.5,
                ),
              ),
              child: child,
            ),
          ),
        ),
        Positioned(top: 0, left: 28, right: 28, child: tabs),
        const Positioned(
          left: -5,
          top: 22,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(54, 54),
              painter: _MissionLeafPainter(),
            ),
          ),
        ),
        const Positioned(
          right: -4,
          bottom: -2,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(58, 58),
              painter: _MissionLeafPainter(flower: true, mirrored: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionLeafPainter extends CustomPainter {
  const _MissionLeafPainter({this.flower = false, this.mirrored = false});

  final bool flower;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrored) {
      canvas.translate(size.width, size.height);
      canvas.rotate(3.14159);
    }
    final stem = Paint()
      ..color = AppColors.oliveDeep
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leafFill = Paint()..color = AppColors.leaf;
    final edge = Paint()
      ..color = AppColors.oliveDeep
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(4, size.height - 5),
      Offset(size.width - 7, 7),
      stem,
    );

    void leaf(Offset center, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: 18, height: 9);
      canvas.drawOval(rect, leafFill);
      canvas.drawOval(rect, edge);
      canvas.restore();
    }

    leaf(Offset(size.width * 0.3, size.height * 0.65), -0.65);
    leaf(Offset(size.width * 0.48, size.height * 0.48), 0.75);
    leaf(Offset(size.width * 0.67, size.height * 0.3), -0.62);

    if (flower) {
      final center = Offset(size.width * 0.72, size.height * 0.22);
      final petal = Paint()..color = AppColors.blossom;
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          center + Offset.fromDirection(i * 1.25664, 7),
          4.8,
          petal,
        );
      }
      canvas.drawCircle(center, 3.8, Paint()..color = AppColors.goldLight);
    }
  }

  @override
  bool shouldRepaint(covariant _MissionLeafPainter oldDelegate) =>
      oldDelegate.flower != flower || oldDelegate.mirrored != mirrored;
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message, required this.mutedForeground});

  final String message;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: mutedForeground),
      ),
    );
  }
}

class _QuestItemCard extends StatelessWidget {
  const _QuestItemCard({
    required this.quest,
    required this.index,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    required this.accent,
    required this.muted,
    required this.dewColor,
    required this.energyColor,
    required this.isClaimLoading,
    required this.cancelRemaining,
    required this.isCancelLoading,
    required this.onClaim,
    required this.onCancel,
  });

  final _QuestDisplayItem quest;
  final int index;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color accent;
  final Color muted;
  final Color dewColor;
  final Color energyColor;
  final bool isClaimLoading;
  final int cancelRemaining;
  final bool isCancelLoading;
  final VoidCallback onClaim;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final safeCurrent = quest.current;
    final progress = quest.target <= 0
        ? 0.0
        : (safeCurrent / quest.target).clamp(0.0, 1.0);
    final isCompleted = quest.isCompleted;
    final showClaim = quest.canClaim && !quest.isClaimed;
    final isClaimed = quest.isClaimed;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedCardColor = isDark
        ? (isClaimed
              ? AppColors.darkMuted.withValues(alpha: 0.58)
              : showClaim
              ? AppColors.darkPrimary.withValues(alpha: 0.98)
              : AppColors.darkNestedCard.withValues(alpha: 0.98))
        : (isClaimed
              ? AppColors.panelMuted.withValues(alpha: 0.78)
              : isCompleted
              ? AppColors.leafLight.withValues(alpha: 0.94)
              : AppColors.authCard.withValues(alpha: 0.94));
    final resolvedBorderColor = isDark
        ? (isClaimed
              ? AppColors.darkCardBorder.withValues(alpha: 0.55)
              : showClaim
              ? AppColors.darkLife
              : AppColors.darkCardBorder)
        : (isClaimed
              ? AppColors.wood.withValues(alpha: 0.55)
              : isCompleted
              ? AppColors.oliveDeep
              : AppColors.wood);
    final resolvedForeground = isDark && isClaimed
        ? AppColors.darkMutedForeground
        : foreground;
    final resolvedMutedForeground = isDark && isClaimed
        ? AppColors.darkMutedForeground.withValues(alpha: 0.72)
        : mutedForeground;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 10),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 15),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: resolvedCardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: resolvedBorderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.woodDeep.withValues(alpha: 0.12),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : Icons.star_border_rounded,
                      size: isCompleted ? 38 : 35,
                      color: isCompleted
                          ? (isDark
                                ? (isClaimed
                                      ? AppColors.darkMutedForeground
                                      : AppColors.darkForeground)
                                : AppColors.success)
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.woodLight),
                      shadows: [
                        Shadow(
                          color: isCompleted
                              ? AppColors.oliveDeep
                              : AppColors.woodDeep.withValues(alpha: 0.7),
                          blurRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: resolvedForeground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: resolvedMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (showClaim)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 72,
                      minHeight: 44,
                    ),
                    child: Material(
                      color: accent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: isClaimLoading ? null : onClaim,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Center(
                            child: isClaimLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : GameButtonLabel(
                                    l10n.missionsClaim,
                                    fontSize: 13.5,
                                    color: resolvedForeground,
                                    outlineWidth: 0,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (quest.isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.woodLight.withValues(alpha: 0.72)
                          : muted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      l10n.missionsClaimed,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: resolvedMutedForeground,
                      ),
                    ),
                  )
                else if (!quest.isChallenge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: muted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${quest.reward}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: resolvedForeground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset(
                          AppAssets.iconDewDrop,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                if (!isCompleted && quest.isChallenge) ...[
                  if (isCancelLoading)
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: cancelRemaining <= 0 ? null : onCancel,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 28,
                        color: cancelRemaining <= 0
                            ? AppColors.woodDeep.withValues(alpha: 0.35)
                            : AppColors.woodDeep,
                      ),
                    ),
                ],
              ],
            ),
            if (quest.isChallenge) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: muted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${quest.reward}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: resolvedForeground,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Image.asset(
                        AppAssets.iconDewDrop,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isClaimed
                            ? AppColors.darkMutedForeground.withValues(
                                alpha: 0.55,
                              )
                            : isCompleted
                            ? AppColors.buttonGreen
                            : energyColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${safeCurrent.clamp(0, quest.target)}/${quest.target}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: resolvedMutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
