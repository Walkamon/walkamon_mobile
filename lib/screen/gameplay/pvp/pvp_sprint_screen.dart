import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../providers/game_state_provider.dart';
import '../../../providers/pvp_provider.dart';
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

  @override
  void dispose() {
    _successPopupTimer?.cancel();
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

  Future<void> _inviteFriend(String name) async {
    setState(() {
      _opponentName = name;
      _gameState = 'waiting-for-friend';
    });

    await context.read<PvpProvider>().sendInvite(name);

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

  void _cancelInvite() {
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
        title: const Text('Thoát trận?'),
        content: const Text(
          'Nếu thoát bây giờ bạn sẽ nhận kết quả THẤT BẠI và đối thủ thắng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát & nhận thua'),
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

  @override
  Widget build(BuildContext context) {
    final pvpProvider = context.watch<PvpProvider>();
    final currentUserId = context.watch<GameStateProvider>().user?.id ?? '';
    if (currentUserId.isNotEmpty &&
        pvpProvider.currentUserId != currentUserId) {
      pvpProvider.setCurrentUserId(currentUserId);
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
        (isProviderFinished ||
            _gameState == 'finished' ||
            awaitingServerResult)
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
            onStartMatchmaking:
                (_gameState == 'waiting' || _gameState == 'finished')
                ? () => _startMatchmaking()
                : null,
            onCancelMatchmaking: _cancelMatchmaking,
            onInviteFriend:
                (_gameState == 'waiting' || _gameState == 'finished')
                ? (name) => _inviteFriend(name)
                : null,
            onShowIncomingChallenges: () => showIncomingChallengesModal(
              context,
              pvpProvider.incomingInvites,
              _acceptChallenge,
              _rejectChallenge,
            ),
            onShowMatchHistory: () => showMatchHistoryModal(
              context,
              currentUserId: currentUserId,
            ),
          )
        else
          PvPRacingEnvironment(
            isMoving: pvpProvider.isRaceRunning,
            myProgress: pvpProvider.myProgress,
            opponentProgress: pvpProvider.opponentProgress,
            opponentName: pvpProvider.currentOpponentName,
            racePhase: pvpProvider.racePhase,
            isFinished: pvpProvider.isRaceFinished,
            onClose: _onCloseRacePressed,
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
          ),
      ],
    );
  }
}
