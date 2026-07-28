import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
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
  PvpMatchmakingState? _lastObservedMatchmakingState;

  @override
  void dispose() {
    _successPopupTimer?.cancel();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    setState(() {
      _gameState = 'matching';
    });

    await context.read<PvpProvider>().startMatchmaking();

    if (!mounted) return;

    final provider = context.read<PvpProvider>();
    if (provider.matchmakingState == PvpMatchmakingState.countdown) {
      setState(() {
        _opponentName = provider.currentOpponentName;
        _gameState = 'room-countdown';
        _showMatchSuccessPopup = true;
      });
      _successPopupTimer?.cancel();
      _successPopupTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _showMatchSuccessPopup = false;
          _gameState = 'racing';
        });
      });
    } else if (provider.matchmakingState == PvpMatchmakingState.running) {
      setState(() {
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
      setState(() {
        _opponentName = provider.currentOpponentName;
        _gameState = 'room-countdown';
      });
      _startRoomCountdown();
    } else if (provider.matchmakingState == PvpMatchmakingState.running) {
      setState(() {
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
      setState(() {
        _opponentName = provider.currentOpponentName;
        _gameState = 'room-countdown';
      });
    } else if (provider.matchmakingState == PvpMatchmakingState.running) {
      setState(() {
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

  void _startRoomCountdown() {
    setState(() {
      _gameState = 'room-countdown';
      _opponentName = context.read<PvpProvider>().currentOpponentName;
    });
  }

  Future<void> _cancelMatchmaking() async {
    await context.read<PvpProvider>().cancelMatchmaking();
    _successPopupTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showMatchSuccessPopup = false;
      _gameState = 'waiting';
      _opponentName = '';
    });
  }

  void _resetGame() {
    _successPopupTimer?.cancel();
    context.read<PvpProvider>().clearMatchState();
    setState(() {
      _showMatchSuccessPopup = false;
      _gameState = 'waiting';
      _opponentName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pvpProvider = context.watch<PvpProvider>();
    if (_lastObservedMatchmakingState != pvpProvider.matchmakingState) {
      _lastObservedMatchmakingState = pvpProvider.matchmakingState;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          switch (pvpProvider.matchmakingState) {
            case PvpMatchmakingState.countdown:
              _showMatchSuccessPopup = true;
              _gameState = 'room-countdown';
              _opponentName = pvpProvider.currentOpponentName;
              _successPopupTimer?.cancel();
              _successPopupTimer = Timer(const Duration(milliseconds: 900), () {
                if (!mounted) return;
                setState(() {
                  _showMatchSuccessPopup = false;
                  _gameState = 'racing';
                });
              });
              break;
            case PvpMatchmakingState.running:
              _showMatchSuccessPopup = false;
              _gameState = 'racing';
              break;
            case PvpMatchmakingState.finished:
              _showMatchSuccessPopup = false;
              _gameState = 'finished';
              break;
            default:
              _showMatchSuccessPopup = false;
              break;
          }
        });
      });
    }
    final isProviderRunning =
        pvpProvider.matchmakingState == PvpMatchmakingState.running;
    final isProviderCountdown =
        pvpProvider.matchmakingState == PvpMatchmakingState.countdown;
    final isProviderConnecting =
        pvpProvider.matchmakingState == PvpMatchmakingState.connecting;

    final effectiveGameState = (isProviderRunning || _gameState == 'racing')
        ? 'racing'
        : isProviderCountdown
        ? 'room-countdown'
        : _gameState;
    final showWaitingRoom = effectiveGameState != 'racing';

    final countdownSeconds = pvpProvider.countdownSecondsRemaining;

    return Stack(
      children: [
        // Background mapping based on state
        if (showWaitingRoom)
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
              pvpProvider.matchHistory,
              'currentUserId',
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
            onClose: _resetGame,
          ),

        // Overlays
        if (isProviderConnecting) PvPMatchingOverlay(),
        if (_showMatchSuccessPopup) const PvPMatchSuccessOverlay(),
        if (isProviderCountdown &&
            _gameState == 'room-countdown' &&
            !_showMatchSuccessPopup)
          PvPRoomCountdownOverlay(
            opponentName: pvpProvider.currentOpponentName,
            countdown: countdownSeconds,
          ),
        if (_gameState == 'waiting-for-friend')
          PvPWaitingFriendOverlay(
            opponentName: _opponentName,
            onCancel: _cancelInvite,
          ),
        if (effectiveGameState == 'finished')
          PvPFinishedOverlay(
            isWin: pvpProvider.myProgress >= 100,
            opponentName: _opponentName,
            onContinue: _resetGame,
          ),
      ],
    );
  }
}
