import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
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
  int _roomCountdown = 5;
  dynamic _racePhase = 'ready'; // 'ready', 3, 2, 1, 'go', 'running'
  double _myProgress = 0;
  double _opponentProgress = 0;
  String _opponentName = '';

  Timer? _stateTimer;
  Timer? _raceTimer;

  @override
  void dispose() {
    _stateTimer?.cancel();
    _raceTimer?.cancel();
    super.dispose();
  }

  void _inviteFriend(String name) {
    setState(() {
      _opponentName = name;
      _gameState = 'waiting-for-friend';
    });
    _stateTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _gameState = 'room-countdown';
      });
      _startRoomCountdown();
    });
  }

  Future<void> _acceptChallenge(String id, String name) async {
    final success = await context.read<PvpProvider>().acceptChallenge(id);
    if (!mounted) return;

    if (success) {
      setState(() {
        _opponentName = name;
        _gameState = 'room-countdown';
      });
      _startRoomCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chấp nhận lời mời. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Future<void> _rejectChallenge(String id) async {
    final success = await context.read<PvpProvider>().rejectChallenge(id);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể từ chối lời mời. Vui lòng thử lại.'),
        ),
      );
    }
  }

  void _cancelInvite() {
    _stateTimer?.cancel();
    setState(() {
      _gameState = 'waiting';
      _opponentName = '';
    });
  }

  Future<void> _cancelMatchmaking() async {
    await context.read<PvpProvider>().cancelMatchmaking();
  }

  void _startRoomCountdown() {
    _roomCountdown = 5;
    _stateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_roomCountdown > 1) {
        setState(() {
          _roomCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _gameState = 'racing';
          _racePhase = 3;
        });
        _startRaceCountdown();
      }
    });
  }

  void _startRaceCountdown() {
    _stateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_racePhase is int) {
        int phase = _racePhase as int;
        if (phase > 1) {
          setState(() {
            _racePhase = phase - 1;
          });
        } else {
          setState(() {
            _racePhase = 'go';
          });
          Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _racePhase = 'running';
              });
              _startRacing();
            }
          });
          timer.cancel();
        }
      }
    });
  }

  void _startRacing() {
    final random = Random();
    _raceTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _myProgress += (random.nextDouble() * 1.5 + 0.2);
        _opponentProgress += (random.nextDouble() * 1.5 + 0.2);

        if (_myProgress >= 100 || _opponentProgress >= 100) {
          _myProgress = min(_myProgress, 100);
          _opponentProgress = min(_opponentProgress, 100);
          timer.cancel();
          Timer(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _gameState = 'finished';
              });
            }
          });
        }
      });
    });
  }

  void _resetGame() {
    _stateTimer?.cancel();
    _raceTimer?.cancel();
    setState(() {
      _gameState = 'waiting';
      _roomCountdown = 5;
      _racePhase = 'ready';
      _myProgress = 0;
      _opponentProgress = 0;
      _opponentName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pvpProvider = context.watch<PvpProvider>();
    final isProviderRunning =
        pvpProvider.matchmakingState == PvpMatchmakingState.running;
    final isProviderCountdown =
        pvpProvider.matchmakingState == PvpMatchmakingState.countdown;
    final isProviderConnecting =
        pvpProvider.matchmakingState == PvpMatchmakingState.connecting;
    final isProviderWaiting =
        pvpProvider.matchmakingState == PvpMatchmakingState.waiting;

    final showWaitingRoom = !isProviderRunning;
    final canStartMatchmaking =
        _gameState == 'waiting' &&
        pvpProvider.matchmakingState == PvpMatchmakingState.idle;

    return Stack(
      children: [
        // Background mapping based on state
        if (showWaitingRoom)
          PvPWaitingRoomScreen(
            pvpProvider: pvpProvider,
            onStartMatchmaking: canStartMatchmaking
                ? () => pvpProvider.startMatchmaking()
                : null,
            onCancelMatchmaking: isProviderWaiting ? _cancelMatchmaking : null,
            onInviteFriend: _gameState == 'waiting' ? _inviteFriend : null,
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
            isMoving: _gameState == 'racing' && _racePhase == 'running',
            myProgress: _myProgress,
            opponentProgress: _opponentProgress,
            opponentName: pvpProvider.currentOpponentName,
            racePhase: _racePhase.toString(),
            isFinished: _gameState == 'finished',
            onClose: _resetGame,
          ),

        // Overlays
        if (isProviderConnecting) PvPMatchingOverlay(),
        if (isProviderCountdown)
          PvPRoomCountdownOverlay(
            opponentName: pvpProvider.currentOpponentName,
            countdown: pvpProvider.countdownSecondsRemaining,
          ),
        if (_gameState == 'waiting-for-friend')
          PvPWaitingFriendOverlay(
            opponentName: _opponentName,
            onCancel: _cancelInvite,
          ),
        if (_gameState == 'finished')
          PvPFinishedOverlay(
            isWin: _myProgress >= 100,
            opponentName: _opponentName,
            onContinue: _resetGame,
          ),
      ],
    );
  }
}
