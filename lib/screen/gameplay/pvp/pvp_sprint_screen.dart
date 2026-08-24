import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/audio/app_audio_service.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/game_button_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/game_state_provider.dart';
import '../../../providers/pvp_provider.dart';
import '../../../providers/tutorial_provider.dart';
import 'pvp_asset_resolver.dart';
import 'pvp_waiting_room_screen.dart';
import 'widgets/pvp_modals.dart';
import 'widgets/pvp_racing_environment.dart';
import 'widgets/pvp_overlays.dart';
import 'widgets/pvp_two_slot_hud.dart';
import '../../../data/models/pvp_item_models.dart';
import '../../../widgets/tutorial/tutorial_context_tip.dart';
import '../../../widgets/tutorial/tutorial_spotlight_overlay.dart';

class PvPSprintScreen extends StatefulWidget {
  const PvPSprintScreen({super.key});

  @override
  State<PvPSprintScreen> createState() => _PvPSprintScreenState();
}

class _PvPSprintScreenState extends State<PvPSprintScreen> {
  String _gameState =
      'waiting'; // waiting, matching, waiting-for-friend, room-countdown, racing, finished
  String _opponentName = '';

  Timer? _successPopupTimer;
  bool _showMatchSuccessPopup = false;
  bool _enterRacingAfterPopup = false;
  PvpMatchmakingState? _lastObservedMatchmakingState;
  bool _isClaimingReward = false;
  bool _isLoadingResult = false;
  String? _resultRequestedForMatchId;
  bool _battleMusicActive = false;
  String? _lastFinishFeedbackKey;
  String? _tutorialAccountKey;
  final GlobalKey _tutorialLobbyKey = GlobalKey(
    debugLabel: 'pvp-tutorial-lobby',
  );
  final GlobalKey _tutorialMatchKey = GlobalKey(
    debugLabel: 'pvp-tutorial-match',
  );
  final GlobalKey _tutorialItemsKey = GlobalKey(
    debugLabel: 'pvp-tutorial-items',
  );
  final GlobalKey _tutorialResultKey = GlobalKey(
    debugLabel: 'pvp-tutorial-result',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<GameStateProvider>().fetchPetVisual());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accountKey = context.read<GameStateProvider>().user?.id.trim();
    if (accountKey == null ||
        accountKey.isEmpty ||
        accountKey == _tutorialAccountKey) {
      return;
    }
    _tutorialAccountKey = accountKey;
    unawaited(context.read<TutorialProvider>().synchronizeAccount(accountKey));
  }

  @override
  void dispose() {
    _successPopupTimer?.cancel();
    AppAudioService.instance.playHomeMusic();
    super.dispose();
  }

  void _showSuccessThenEnterRacing({required String opponentName}) {
    _successPopupTimer?.cancel();
    setState(() {
      _opponentName = opponentName;
      _gameState = 'room-countdown';
      _showMatchSuccessPopup = true;
      _enterRacingAfterPopup = false;
    });
    _successPopupTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _showMatchSuccessPopup = false;
        _enterRacingAfterPopup = true;
        _gameState = 'room-countdown';
      });
    });
  }

  Future<void> _startMatchmaking() async {
    final tutorial = context.read<TutorialProvider>();
    final pvpProvider = context.read<PvpProvider>();
    if (tutorial.pvpStep == PvpTutorialStep.matchmaking) {
      await tutorial.advancePvp(PvpTutorialStep.matchmaking);
    }
    if (!mounted) return;
    setState(() {
      _gameState = 'matching';
    });

    await pvpProvider.startMatchmaking();

    if (!mounted) return;

    final provider = pvpProvider;
    if (provider.matchmakingState == PvpMatchmakingState.countdown) {
      _showSuccessThenEnterRacing(opponentName: provider.currentOpponentName);
    } else if (provider.matchmakingState == PvpMatchmakingState.running) {
      setState(() {
        _enterRacingAfterPopup = true;
        _showMatchSuccessPopup = false;
        _gameState = 'racing';
      });
    } else if (provider.matchmakingState == PvpMatchmakingState.waiting ||
        provider.matchmakingState == PvpMatchmakingState.connecting) {
      setState(() {
        _gameState = 'matching';
      });
    } else {
      setState(() {
        _gameState = 'waiting';
      });
    }
  }

  Future<void> _inviteFriend(String userId, String username) async {
    setState(() {
      _opponentName = username;
      _gameState = 'waiting-for-friend';
    });

    await context.read<PvpProvider>().sendInvite(userId);

    if (!mounted) return;

    final provider = context.read<PvpProvider>();
    if (provider.matchmakingState == PvpMatchmakingState.countdown) {
      _showSuccessThenEnterRacing(opponentName: provider.currentOpponentName);
    } else if (provider.matchmakingState == PvpMatchmakingState.running) {
      setState(() {
        _enterRacingAfterPopup = true;
        _showMatchSuccessPopup = false;
        _gameState = 'racing';
      });
    } else if (provider.matchmakingState == PvpMatchmakingState.invitePending) {
      setState(() {
        _gameState = 'waiting-for-friend';
      });
    } else {
      setState(() {
        _gameState = 'waiting';
      });
    }
  }

  Future<void> _acceptChallenge(String id, String name) async {
    await context.read<PvpProvider>().respondToInvite(id, accept: true);

    if (!mounted) return;

    final provider = context.read<PvpProvider>();
    if (provider.matchmakingState == PvpMatchmakingState.countdown) {
      _showSuccessThenEnterRacing(opponentName: provider.currentOpponentName);
    } else if (provider.matchmakingState == PvpMatchmakingState.running) {
      setState(() {
        _enterRacingAfterPopup = true;
        _showMatchSuccessPopup = false;
        _gameState = 'racing';
      });
    }
  }

  Future<void> _rejectChallenge(String id) async {
    await context.read<PvpProvider>().respondToInvite(id, accept: false);
  }

  Future<void> _cancelInvite() async {
    await context.read<PvpProvider>().cancelInvite();
    if (!mounted) return;
    setState(() {
      _gameState = 'waiting';
      _opponentName = '';
    });
  }

  Future<void> _cancelMatchmaking() async {
    await context.read<PvpProvider>().cancelMatchmaking();
    _successPopupTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showMatchSuccessPopup = false;
      _enterRacingAfterPopup = false;
      _gameState = 'waiting';
      _opponentName = '';
    });
  }

  void _resetGame() {
    _successPopupTimer?.cancel();
    AppAudioService.instance.playHomeMusic();
    context.read<PvpProvider>().clearMatchState();
    setState(() {
      _showMatchSuccessPopup = false;
      _enterRacingAfterPopup = false;
      _isClaimingReward = false;
      _isLoadingResult = false;
      _resultRequestedForMatchId = null;
      _lastFinishFeedbackKey = null;
      _gameState = 'waiting';
      _opponentName = '';
    });
  }

  Future<void> _onCloseRacePressed() async {
    if (_isLoadingResult) return;
    final l10n = AppLocalizations.of(context);
    final provider = context.read<PvpProvider>();
    final isRacing =
        provider.matchmakingState == PvpMatchmakingState.running ||
        provider.matchmakingState == PvpMatchmakingState.countdown;

    if (!isRacing || provider.isRaceFinished) {
      _resetGame();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.authCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.wood,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.woodDeep.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameButtonLabel(
                l10n.pvpExitMatchTitle,
                fontSize: 22,
                color: AppColors.woodDeep,
                outlineColor: AppColors.authCard,
                outlineWidth: 3,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.pvpExitMatchMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.woodDeep,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkForeground
                            : AppColors.woodDeep,
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.woodDeep,
                          width: 2,
                        ),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkMuted
                            : AppColors.buttonSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(l10n.pvpStayInMatch),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextOutline
                            : AppColors.buttonText,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkLife
                            : AppColors.buttonGreen,
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkBorder
                              : AppColors.woodDeep,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(l10n.pvpExitAndForfeit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _gameState = 'finished';
      _isLoadingResult = true;
    });

    await provider.forfeitMatch();
    if (!mounted) return;

    setState(() {
      _isLoadingResult = false;
      _gameState = 'finished';
      _opponentName = provider.currentOpponentName.isNotEmpty
          ? provider.currentOpponentName
          : _opponentName;
    });
  }

  Future<void> _ensureMatchResultLoaded(PvpProvider provider) async {
    final matchId = provider.activeMatchId;
    if (matchId == null || matchId.isEmpty) return;
    if (provider.matchResult != null) return;
    if (_resultRequestedForMatchId == matchId && _isLoadingResult) return;

    setState(() {
      _isLoadingResult = true;
      _resultRequestedForMatchId = matchId;
    });
    await provider.loadMatchResult(matchId);
    if (!mounted) return;
    setState(() {
      _isLoadingResult = false;
    });
  }

  Future<void> _claimReward() async {
    final provider = context.read<PvpProvider>();
    final matchId = provider.activeMatchId ?? provider.matchResult?.matchId;
    if (matchId == null || matchId.isEmpty) return;

    setState(() => _isClaimingReward = true);
    final success = await provider.claimMatchReward(matchId);
    if (!mounted) return;

    if (success) {
      final reward = provider.lastClaimResponse;
      final gameState = context.read<GameStateProvider>();
      final user = gameState.user;
      if (reward != null && user != null) {
        gameState.setUser(user.copyWith(coins: reward.walletBalance));
      }
    }
    setState(() => _isClaimingReward = false);
  }

  void _syncMatchMusic(PvpProvider provider) {
    final matchId = provider.activeMatchId;
    final hasAssignedMatch =
        matchId != null &&
        matchId.isNotEmpty &&
        provider.matchmakingState != PvpMatchmakingState.idle &&
        provider.matchmakingState != PvpMatchmakingState.cancelled;

    if (_battleMusicActive == hasAssignedMatch) return;
    _battleMusicActive = hasAssignedMatch;
    if (hasAssignedMatch) {
      AppAudioService.instance.playBattleMusic();
    } else {
      AppAudioService.instance.playHomeMusic();
    }
  }

  Widget _buildItemHud(BuildContext context, PvpProvider provider) {
    PvpLoadoutSlot? slotAt(int slotNo) {
      for (final slot in provider.itemLoadout) {
        if (slot.slotNo == slotNo) return slot;
      }
      return null;
    }

    PvpHudSlot visualSlot(int slotNo) {
      final slot = slotAt(slotNo);
      return PvpHudSlot(
        itemCode: slot?.presentationCode ?? 'haste',
        enabled: slot?.isAvailable ?? false,
        used: slot?.isUsed ?? false,
        pending: provider.pendingItemSlots.contains(slotNo),
        quantity: slot?.quantity,
        onTap: slot == null ? null : () => provider.useItem(slotNo),
      );
    }

    final feedback = provider.itemFeedback;
    final l10n = AppLocalizations.of(context);
    final feedbackText = switch (feedback) {
      PvpItemFeedbackCode.onlyDuringRace => l10n.pvpItemOnlyDuringRace,
      PvpItemFeedbackCode.slotUnavailable => l10n.pvpItemSlotUnavailable,
      PvpItemFeedbackCode.useFailed => l10n.pvpItemUseFailed,
      PvpItemFeedbackCode.blocked => l10n.pvpItemBlocked,
      PvpItemFeedbackCode.cleansed => l10n.pvpItemCleansed,
      PvpItemFeedbackCode.used => l10n.pvpItemUsed,
      null => null,
    };
    return Positioned(
      left: 18,
      right: 18,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (feedbackText != null)
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.64),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    feedbackText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ConstrainedBox(
              key: _tutorialItemsKey,
              constraints: const BoxConstraints(maxWidth: 280),
              child: PvpTwoSlotHud(left: visualSlot(1), right: visualSlot(2)),
            ),
          ],
        ),
      ),
    );
  }

  void _syncFinishFeedback({
    required PvpProvider provider,
    required String? resultCode,
    required bool showFinishReaction,
  }) {
    if (!showFinishReaction || resultCode == null) return;
    final matchId =
        provider.activeMatchId ?? provider.matchResult?.matchId ?? '';
    final key = '$matchId:$resultCode';
    if (_lastFinishFeedbackKey == key) return;
    _lastFinishFeedbackKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (resultCode) {
        case 'win':
          unawaited(AppAudioService.instance.playPvpWin());
          unawaited(AppHaptics.success());
        case 'lose':
          unawaited(AppAudioService.instance.playPvpLose());
          unawaited(AppHaptics.warning());
        default:
          unawaited(AppHaptics.mediumImpact());
      }
    });
  }

  Widget _buildPvpTutorial(
    BuildContext context, {
    required TutorialProvider tutorial,
    required PvpProvider provider,
    required bool showRacingTrack,
    required bool showFinishReaction,
    required bool finishPresentationComplete,
  }) {
    final l10n = AppLocalizations.of(context);
    return switch (tutorial.pvpStep) {
      PvpTutorialStep.lobby when !showRacingTrack => TutorialSpotlightOverlay(
        key: const ValueKey('pvp-tutorial-lobby'),
        targetKey: _tutorialLobbyKey,
        title: l10n.tutorialPvpLobbyTitle,
        description: l10n.tutorialPvpLobbyBody,
        stepLabel: l10n.tutorialStepLabel(1, 6),
        skipLabel: l10n.tutorialSkip,
        onSkip: tutorial.skipPvp,
        nextLabel: l10n.tutorialNext,
        onNext: () => tutorial.advancePvp(PvpTutorialStep.lobby),
      ),
      PvpTutorialStep.matchmaking when !showRacingTrack =>
        TutorialSpotlightOverlay(
          key: const ValueKey('pvp-tutorial-matchmaking'),
          targetKey: _tutorialMatchKey,
          title: l10n.tutorialPvpMatchTitle,
          description: l10n.tutorialPvpMatchBody,
          stepLabel: l10n.tutorialStepLabel(2, 6),
          skipLabel: l10n.tutorialSkip,
          onSkip: tutorial.skipPvp,
          targetSemanticLabel: l10n.pvpFindRandomMatch,
          onTargetTap: _startMatchmaking,
        ),
      PvpTutorialStep.race
          when showRacingTrack &&
              !showFinishReaction &&
              !finishPresentationComplete =>
        TutorialContextTip(
          key: const ValueKey('pvp-tutorial-race'),
          title: l10n.tutorialPvpRaceTitle,
          description: l10n.tutorialPvpRaceBody,
          stepLabel: l10n.tutorialStepLabel(3, 6),
          actionLabel: l10n.tutorialGotIt,
          skipLabel: l10n.tutorialSkip,
          onAction: () => tutorial.advancePvp(PvpTutorialStep.race),
          onSkip: tutorial.skipPvp,
        ),
      PvpTutorialStep.items
          when showRacingTrack &&
              !showFinishReaction &&
              !finishPresentationComplete =>
        TutorialContextTip(
          key: const ValueKey('pvp-tutorial-items'),
          title: l10n.tutorialPvpItemsTitle,
          description: provider.itemLoadout.isEmpty
              ? l10n.tutorialPvpItemsEmptyBody
              : l10n.tutorialPvpItemsBody,
          stepLabel: l10n.tutorialStepLabel(4, 6),
          actionLabel: l10n.tutorialGotIt,
          skipLabel: l10n.tutorialSkip,
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(42, 0, 42, 112),
          onAction: () => tutorial.advancePvp(PvpTutorialStep.items),
          onSkip: tutorial.skipPvp,
        ),
      PvpTutorialStep.finish when showRacingTrack && showFinishReaction =>
        TutorialContextTip(
          key: const ValueKey('pvp-tutorial-finish'),
          title: l10n.tutorialPvpFinishTitle,
          description: l10n.tutorialPvpFinishBody,
          stepLabel: l10n.tutorialStepLabel(5, 6),
          actionLabel: l10n.tutorialGotIt,
          skipLabel: l10n.tutorialSkip,
          onAction: () => tutorial.advancePvp(PvpTutorialStep.finish),
          onSkip: tutorial.skipPvp,
        ),
      PvpTutorialStep.result when finishPresentationComplete =>
        TutorialContextTip(
          key: const ValueKey('pvp-tutorial-result'),
          title: l10n.tutorialPvpResultTitle,
          description: l10n.tutorialPvpResultBody,
          stepLabel: l10n.tutorialStepLabel(6, 6),
          actionLabel: l10n.tutorialGotIt,
          skipLabel: l10n.tutorialSkip,
          alignment: Alignment.topCenter,
          margin: const EdgeInsets.fromLTRB(32, 18, 32, 0),
          onAction: () => tutorial.advancePvp(PvpTutorialStep.result),
          onSkip: tutorial.skipPvp,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pvpProvider = context.watch<PvpProvider>();
    final gameState = context.watch<GameStateProvider>();
    final tutorial = context.watch<TutorialProvider>();
    final l10n = AppLocalizations.of(context);
    final providerOpponentName = pvpProvider.currentOpponentName.trim();
    final opponentDisplayName = providerOpponentName.isNotEmpty
        ? providerOpponentName
        : l10n.pvpOpponent;
    _syncMatchMusic(pvpProvider);
    final currentUserId = gameState.user?.id ?? '';
    if (currentUserId.isNotEmpty &&
        pvpProvider.currentUserId != currentUserId) {
      pvpProvider.setCurrentUserId(currentUserId);
    }

    if (pvpProvider.inviteDeclined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        pvpProvider.clearInviteDeclined();
        showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.42),
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                decoration: BoxDecoration(
                  color: AppColors.authCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.woodDeep, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.woodDeep.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameButtonLabel(
                      l10n.pvpNoticeTitle,
                      fontSize: 24,
                      color: AppColors.authCard,
                      outlineColor: AppColors.woodDeep,
                      outlineWidth: 4,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.pvpInviteDeclined,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.woodDeep,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Theme.of(dialogContext).brightness ==
                                  Brightness.dark
                              ? AppColors.darkTextOutline
                              : AppColors.buttonText,
                          backgroundColor:
                              Theme.of(dialogContext).brightness ==
                                  Brightness.dark
                              ? AppColors.darkLife
                              : AppColors.buttonGreen,
                          side: BorderSide(
                            color:
                                Theme.of(dialogContext).brightness ==
                                    Brightness.dark
                                ? AppColors.darkBorder
                                : AppColors.woodDeep,
                            width: 2,
                          ),
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: GameButtonLabel(l10n.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    }

    if (_lastObservedMatchmakingState != pvpProvider.matchmakingState) {
      _lastObservedMatchmakingState = pvpProvider.matchmakingState;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (pvpProvider.matchmakingState) {
          case PvpMatchmakingState.countdown:
            if (!_showMatchSuccessPopup && !_enterRacingAfterPopup) {
              _showSuccessThenEnterRacing(
                opponentName: pvpProvider.currentOpponentName,
              );
            } else {
              setState(() {
                _opponentName = pvpProvider.currentOpponentName;
                _gameState = 'room-countdown';
              });
            }
            break;
          case PvpMatchmakingState.running:
            unawaited(context.read<GameStateProvider>().fetchPetStatus());
            setState(() {
              _showMatchSuccessPopup = false;
              _enterRacingAfterPopup = true;
              _gameState = 'racing';
            });
            break;
          case PvpMatchmakingState.finished:
            unawaited(context.read<GameStateProvider>().fetchPetStatus());
            setState(() {
              _showMatchSuccessPopup = false;
              _gameState = 'finished';
              _opponentName = pvpProvider.currentOpponentName.isNotEmpty
                  ? pvpProvider.currentOpponentName
                  : _opponentName;
            });
            unawaited(_ensureMatchResultLoaded(pvpProvider));
            break;
          case PvpMatchmakingState.cancelled:
            unawaited(context.read<GameStateProvider>().fetchPetStatus());
            setState(() {
              _showMatchSuccessPopup = false;
              _enterRacingAfterPopup = false;
              _gameState = 'waiting';
              _opponentName = '';
            });
            break;
          case PvpMatchmakingState.idle:
            if (_gameState == 'waiting-for-friend' ||
                _gameState == 'matching') {
              setState(() {
                _gameState = 'waiting';
                _opponentName = '';
                _showMatchSuccessPopup = false;
              });
            }
            break;
          default:
            break;
        }
      });
    }

    final isProviderRunning =
        pvpProvider.matchmakingState == PvpMatchmakingState.running;
    final isProviderCountdown =
        pvpProvider.matchmakingState == PvpMatchmakingState.countdown;
    final isProviderConnecting =
        pvpProvider.matchmakingState == PvpMatchmakingState.connecting;
    final isProviderFinished =
        pvpProvider.matchmakingState == PvpMatchmakingState.finished;
    final isProviderCancelled =
        pvpProvider.matchmakingState == PvpMatchmakingState.cancelled;
    final awaitingServerResult =
        pvpProvider.isRaceFinished &&
        !isProviderFinished &&
        !isProviderCancelled &&
        pvpProvider.matchResult == null;

    final effectiveGameState =
        (isProviderFinished || _gameState == 'finished' || awaitingServerResult)
        ? 'finished'
        : (isProviderRunning || _gameState == 'racing')
        ? 'racing'
        : isProviderCountdown
        ? 'room-countdown'
        : _gameState;

    final resultCode =
        (pvpProvider.forcedResultCode?.trim().isNotEmpty == true
            ? pvpProvider.forcedResultCode!.trim().toLowerCase()
            : null) ??
        pvpProvider.matchResult?.resultCodeForUser(currentUserId);
    final finishPresentationComplete = pvpProvider.finishPresentationCompleted;
    final showFinishReaction = pvpProvider.isFinishReacting;
    _syncFinishFeedback(
      provider: pvpProvider,
      resultCode: resultCode,
      showFinishReaction: showFinishReaction,
    );
    final myFinishAnimation = showFinishReaction && resultCode == 'win'
        ? 'win'
        : showFinishReaction && resultCode == 'lose'
        ? 'lose'
        : 'race';
    final opponentFinishAnimation = showFinishReaction && resultCode == 'win'
        ? 'lose'
        : showFinishReaction && resultCode == 'lose'
        ? 'win'
        : 'race';
    String? myMatchPlayerId;
    for (final participant
        in pvpProvider.currentMatch?.participants ?? const []) {
      if (participant.userId == currentUserId) {
        myMatchPlayerId = participant.matchPlayerId;
        break;
      }
    }
    final myEffectCodes = pvpProvider.activeEffects
        .where((effect) => effect.targetMatchPlayerId == myMatchPlayerId)
        .map((effect) => effect.presentationCode)
        .whereType<String>()
        .toList(growable: false);
    final opponentEffectCodes = pvpProvider.activeEffects
        .where((effect) => effect.targetMatchPlayerId != myMatchPlayerId)
        .map((effect) => effect.presentationCode)
        .whereType<String>()
        .toList(growable: false);

    // After success popup dismisses → show racing track for countdown + race.
    final showRacingTrack =
        _enterRacingAfterPopup &&
        (isProviderCountdown ||
            isProviderRunning ||
            _gameState == 'racing' ||
            _gameState == 'room-countdown' ||
            effectiveGameState == 'finished');

    if (tutorial.shouldShowPvp && showRacingTrack) {
      final needsResultContext =
          finishPresentationComplete &&
          tutorial.pvpStep.index < PvpTutorialStep.result.index;
      final needsFinishContext =
          showFinishReaction &&
          tutorial.pvpStep.index < PvpTutorialStep.finish.index;
      final needsRaceContext =
          !showFinishReaction &&
          !finishPresentationComplete &&
          tutorial.pvpStep.index < PvpTutorialStep.race.index;
      if (needsResultContext || needsFinishContext || needsRaceContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (needsResultContext) {
            unawaited(tutorial.enterPvpResultContext());
          } else if (needsFinishContext) {
            unawaited(tutorial.enterPvpFinishContext());
          } else {
            unawaited(tutorial.enterPvpRaceContext());
          }
        });
      }
    }

    return Stack(
      children: [
        if (!showRacingTrack)
          PvPWaitingRoomScreen(
            pvpProvider: pvpProvider,
            activePetAffinityCode: gameState.affinityCode,
            activePetStageNo: gameState.petStageNo,
            activePetAnimationType: gameState.animationType,
            onStartMatchmaking:
                (_gameState == 'waiting' || _gameState == 'finished')
                ? () => _startMatchmaking()
                : null,
            onCancelMatchmaking: _cancelMatchmaking,
            onInviteFriend:
                (_gameState == 'waiting' || _gameState == 'finished')
                ? (userId, username) => _inviteFriend(userId, username)
                : null,
            onShowIncomingChallenges: () => showIncomingChallengesModal(
              context,
              pvpProvider.incomingInvites,
              _acceptChallenge,
              _rejectChallenge,
            ),
            onShowMatchHistory: () =>
                showMatchHistoryModal(context, currentUserId: currentUserId),
            lobbyTutorialKey: _tutorialLobbyKey,
            matchmakingTutorialKey: _tutorialMatchKey,
          )
        else
          PvPRacingEnvironment(
            isMoving: pvpProvider.isRaceRunning,
            trackProgress: pvpProvider.raceTimeProgress,
            myProgress: pvpProvider.myProgress,
            opponentProgress: pvpProvider.opponentProgress,
            opponentName: opponentDisplayName,
            racePhase: pvpProvider.racePhase,
            isFinished: finishPresentationComplete,
            showFinishReaction: showFinishReaction,
            finishResultCode: resultCode,
            onWinnerCrossed: pvpProvider.markFinishLineCrossed,
            onClose: _onCloseRacePressed,
            mapAssets: PvpAssetResolver.mapsForNow(
              pvpProvider.estimatedServerNow(),
            ),
            myAffinityCode: gameState.affinityCode,
            opponentAffinityCode: pvpProvider.opponentSpiritAffinityCode,
            myStageNo: gameState.petStageNo,
            myAnimationState: myFinishAnimation,
            opponentAnimationState: opponentFinishAnimation,
            myActiveEffects: myEffectCodes,
            opponentActiveEffects: opponentEffectCodes,
            myTransientEffect: pvpProvider.transientVfxOnMyPet
                ? pvpProvider.transientVfxCode
                : null,
            opponentTransientEffect: pvpProvider.transientVfxOnMyPet
                ? null
                : pvpProvider.transientVfxCode,
            transientVfxSequence: pvpProvider.transientVfxSequence,
          ),

        if (showRacingTrack &&
            !finishPresentationComplete &&
            !pvpProvider.isFinishReconciling)
          _buildItemHud(context, pvpProvider),

        if (isProviderConnecting) const PvPMatchingOverlay(),
        if (_showMatchSuccessPopup)
          PvPMatchSuccessOverlay(
            myAffinityCode: gameState.affinityCode,
            myStageNo: gameState.petStageNo,
            opponentAffinityCode: pvpProvider.opponentSpiritAffinityCode,
          ),
        if (_gameState == 'waiting-for-friend')
          PvPWaitingFriendOverlay(
            opponentName: _opponentName,
            onCancel: _cancelInvite,
          ),
        if (finishPresentationComplete)
          KeyedSubtree(
            key: _tutorialResultKey,
            child: PvPFinishedOverlay(
              result: pvpProvider.matchResult,
              isLoading:
                  _isLoadingResult ||
                  (awaitingServerResult &&
                      pvpProvider.forcedResultCode == null) ||
                  (isProviderFinished &&
                      pvpProvider.matchResult == null &&
                      pvpProvider.forcedResultCode == null),
              currentUserId: currentUserId,
              forcedResultCode: pvpProvider.forcedResultCode,
              opponentName: _opponentName.isNotEmpty
                  ? _opponentName
                  : pvpProvider.currentOpponentName,
              onContinue: _resetGame,
              onClaimReward: _claimReward,
              isClaiming: _isClaimingReward,
              claimResponse: pvpProvider.lastClaimResponse,
            ),
          ),
        if (tutorial.shouldShowPvp)
          _buildPvpTutorial(
            context,
            tutorial: tutorial,
            provider: pvpProvider,
            showRacingTrack: showRacingTrack,
            showFinishReaction: showFinishReaction,
            finishPresentationComplete: finishPresentationComplete,
          ),
      ],
    );
  }
}
