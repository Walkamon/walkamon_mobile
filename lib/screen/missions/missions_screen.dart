import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/player_challenge_response.dart';
import '../../data/models/player_mission_response.dart';
import '../../data/repositories/missions_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/game_notification_dialog.dart';

enum MissionTab { mission, challenge }

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _QuestDisplayItem _fromMission(
    PlayerMissionItemResponse mission,
    AppLocalizations l10n,
  ) {
    final claimed = mission.statusCode.toLowerCase() == 'claimed';
    return _QuestDisplayItem(
      missionId: mission.missionId,
      userMissionId: mission.userMissionId,
      title: mission.title,
      description: mission.description?.trim().isNotEmpty == true
          ? mission.description!.trim()
          : l10n.missionsDefaultDescription,
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
    return _QuestDisplayItem(
      missionId: challenge.challengeId,
      userMissionId: challenge.userMissionId,
      title: challenge.title,
      description: challenge.description?.trim().isNotEmpty == true
          ? challenge.description!.trim()
          : l10n.missionsChallengeDescription,
      target: challenge.targetValue,
      current: challenge.progressValue,
      reward: challenge.walletAmount,
      isChallenge: true,
      canClaim: false,
      isClaimed: false,
      isCancelable: challenge.isCancelable,
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final missionsFuture = _repository.getAllMissions();
      final challengeFuture = _repository.getChallengeState();
      final results = await Future.wait([missionsFuture, challengeFuture]);
      final missions = results[0] as PlayerMissionListResponse;
      final challengeState = results[1] as PlayerChallengeStateResponse;

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _dailyQuests = missions.dailyMissions
            .map((mission) => _fromMission(mission, l10n))
            .toList();
        _overallQuests = missions.overallMissions
            .map((mission) => _fromMission(mission, l10n))
            .toList();
        _challengeQuests = challengeState.currentChallenge != null
            ? [_fromChallenge(challengeState.currentChallenge!, l10n)]
            : [];
        _cancelLimit = challengeState.cancelLimit;
        _cancelRemaining = challengeState.cancelRemaining;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dailyQuests = [];
        _overallQuests = [];
        _challengeQuests = [];
        _errorMessage = AppLocalizations.of(context).missionsLoadError;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleClaim(_QuestDisplayItem quest) async {
    if (!quest.canClaim || quest.isChallenge) return;

    setState(() => _claimingMissionId = quest.missionId);
    final provider = context.read<GameStateProvider>();
    try {
      final result = await _repository.claimMission(quest.missionId);
      final user = provider.user;
      if (user != null) {
        provider.setUser(user.copyWith(coins: result.walletBalance));
      }

      if (mounted) {
        _showSuccess(
          AppLocalizations.of(
            context,
          ).missionsClaimSuccess(result.walletAmount),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context).missionsClaimFailed('$e'));
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
        _showError(resp.message);
      }
    } catch (e) {
      _showError(AppLocalizations.of(context).missionsClaimFailed('$e'));
    } finally {
      if (mounted) setState(() => _creatingChallenge = null);
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
        _showMessage(AppLocalizations.of(context).missionsChallengeCanceled);
      } else {
        _showError(resp.message);
      }
    } catch (e) {
      _showError(AppLocalizations.of(context).missionsCancelFailed('$e'));
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
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final dewColor = isDark ? AppColors.darkDew : AppColors.lightDew;
    final energyColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              children: [
                _MissionsHeader(
                  title: l10n.missionsTitle,
                  foreground: foreground,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  onBack: () => Navigator.pushNamed(context, '/home'),
                ),
                const SizedBox(height: 24),
                _MissionTabs(
                  missionLabel: l10n.missionsTabMission,
                  challengeLabel: l10n.missionsTabChallenge,
                  activeTab: _activeTab,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  foreground: foreground,
                  mutedForeground: mutedForeground,
                  onChanged: (tab) => setState(() => _activeTab = tab),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null &&
                      _dailyQuests.isEmpty &&
                      _overallQuests.isEmpty &&
                      _challengeQuests.isEmpty
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: mutedForeground),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                      children: [
                        if (_activeTab == MissionTab.mission) ...[
                          _SectionTitle(
                            title: l10n.missionsDailyTitle,
                            foreground: foreground,
                          ),
                          const SizedBox(height: 16),
                          if (_dailyQuests.isEmpty)
                            _EmptySection(
                              message: l10n.missionsDailyEmpty,
                              mutedForeground: mutedForeground,
                            )
                          else
                            ..._dailyQuests.asMap().entries.map(
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
                          const SizedBox(height: 18),
                          _SectionTitle(
                            title: l10n.missionsOverallTitle,
                            foreground: foreground,
                          ),
                          const SizedBox(height: 16),
                          if (_overallQuests.isEmpty)
                            _EmptySection(
                              message: l10n.missionsOverallEmpty,
                              mutedForeground: mutedForeground,
                            )
                          else
                            ..._overallQuests.asMap().entries.map(
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
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.missionsRandomChallenge,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: foreground,
                                ),
                              ),
                              Text(
                                l10n.missionsCancelRemaining(
                                  _cancelRemaining,
                                  _cancelLimit,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _cancelRemaining <= 0
                                      ? Theme.of(context).colorScheme.error
                                      : mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_challengeQuests.isEmpty)
                            Material(
                              color: cardColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                onTap: _creatingChallenge != null
                                    ? null
                                    : _handleRandomChallenge,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: double.infinity,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: borderColor,
                                      style: BorderStyle.solid,
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
                                            Icon(
                                              Icons.shuffle,
                                              size: 16,
                                              color: energyColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              l10n.missionsNewChallenge,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: mutedForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          if (_challengeQuests.isEmpty) ...[
                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                l10n.missionsNoActiveChallenge,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: mutedForeground,
                                ),
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
                  ),
          ),
        ],
      ),
    );
  }
}

class _MissionsHeader extends StatelessWidget {
  const _MissionsHeader({
    required this.title,
    required this.foreground,
    required this.cardColor,
    required this.borderColor,
    required this.onBack,
  });

  final String title;
  final Color foreground;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: cardColor,
            shape: CircleBorder(side: BorderSide(color: borderColor)),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.chevron_left, size: 20),
              ),
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
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
    Widget buildTab(String label, MissionTab tab) {
      final isActive = activeTab == tab;
      return Expanded(
        child: Material(
          color: isActive ? cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? Border.all(color: borderColor.withValues(alpha: 0.3))
                    : null,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? foreground : mutedForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          buildTab(missionLabel, MissionTab.mission),
          buildTab(challengeLabel, MissionTab.challenge),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.foreground});

  final String title;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
    );
  }
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? Colors.amber.withValues(alpha: 0.4)
                : borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.amber : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted ? Colors.amber : borderColor,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: 14, color: cardColor)
                      : null,
                ),
                const SizedBox(width: 12),
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
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isCompleted && quest.isChallenge)
                  Material(
                    color: cancelRemaining <= 0
                        ? muted.withValues(alpha: 0.3)
                        : muted.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: cancelRemaining <= 0 || isCancelLoading
                          ? null
                          : onCancel,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: isCancelLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: cancelRemaining <= 0
                                    ? mutedForeground.withValues(alpha: 0.3)
                                    : mutedForeground,
                              ),
                      ),
                    ),
                  ),
                if (showClaim)
                  Material(
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
                        child: isClaimLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.missionsClaim,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
                      color: muted,
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
                        color: mutedForeground,
                      ),
                    ),
                  )
                else
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
                            color: foreground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DewdropIcon(size: 16, color: dewColor),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
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
                        isCompleted ? Colors.amber : energyColor,
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
                    color: mutedForeground,
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
