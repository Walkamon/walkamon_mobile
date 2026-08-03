import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/audio/app_audio_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/game_state_provider.dart';
import '../../../providers/pvp_provider.dart';
import 'pvp_asset_resolver.dart';
import 'pvp_waiting_room_screen.dart';
import 'widgets/pvp_modals.dart';
import 'widgets/pvp_racing_environment.dart';
import 'widgets/pvp_overlays.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<GameStateProvider>().fetchPetVisual());
    });
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
    _successPopupTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _showMatchSuccessPopup = false;
        _enterRacingAfterPopup = true;
        _gameState = 'room-countdown';
      });
    });
  }

  Future<void> _startMatchmaking() async {
    setState(() {
      _gameState = 'matching';
    });

    await context.read<PvpProvider>().startMatchmaking();

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
      builder: (context) => AlertDialog(
        title: Text(l10n.pvpExitMatchTitle),
        content: Text(l10n.pvpExitMatchMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.pvpStayInMatch),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pvpExitAndForfeit),
          ),
        ],
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
    await provider.claimMatchReward(matchId);
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final pvpProvider = context.watch<PvpProvider>();
    final gameState = context.watch<GameStateProvider>();
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.pvpNoticeTitle),
            content: Text(l10n.pvpInviteDeclined),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
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
            setState(() {
              _showMatchSuccessPopup = false;
              _enterRacingAfterPopup = true;
              _gameState = 'racing';
            });
            break;
          case PvpMatchmakingState.finished:
            setState(() {
              _showMatchSuccessPopup = false;
              _gameState = 'finished';
              _opponentName = pvpProvider.currentOpponentName.isNotEmpty
                  ? pvpProvider.currentOpponentName
                  : _opponentName;
            });
            unawaited(_ensureMatchResultLoaded(pvpProvider));
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

    // After success popup dismisses → show racing track for countdown + race.
    final showRacingTrack =
        _enterRacingAfterPopup &&
        (isProviderCountdown ||
            isProviderRunning ||
            _gameState == 'racing' ||
            _gameState == 'room-countdown' ||
            effectiveGameState == 'finished');

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
          )
        else
          PvPRacingEnvironment(
            isMoving: pvpProvider.isRaceRunning,
            trackProgress: pvpProvider.raceTimeProgress,
            myProgress: pvpProvider.myProgress,
            opponentProgress: pvpProvider.opponentProgress,
            opponentName: opponentDisplayName,
            racePhase: pvpProvider.racePhase,
            isFinished: pvpProvider.isRaceFinished,
            onClose: _onCloseRacePressed,
            mapAssets: PvpAssetResolver.mapsForNow(
              pvpProvider.estimatedServerNow(),
            ),
            myAffinityCode: gameState.affinityCode,
            opponentAffinityCode: pvpProvider.opponentSpiritAffinityCode,
            myStageNo: gameState.petStageNo,
          ),

        if (isProviderConnecting) const PvPMatchingOverlay(),
        if (_showMatchSuccessPopup) const PvPMatchSuccessOverlay(),
        if (_gameState == 'waiting-for-friend')
          PvPWaitingFriendOverlay(
            opponentName: _opponentName,
            onCancel: _cancelInvite,
          ),
        if (effectiveGameState == 'finished')
          PvPFinishedOverlay(
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
      ],
    );
  }
}
