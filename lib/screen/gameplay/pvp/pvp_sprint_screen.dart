import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'models.dart';
import 'widgets/pvp_modals.dart';
import 'widgets/pvp_racing_environment.dart';
import 'widgets/pvp_overlays.dart';

class PvPSprintScreen extends StatefulWidget {
  const PvPSprintScreen({super.key});

  @override
  State<PvPSprintScreen> createState() => _PvPSprintScreenState();
}

class _PvPSprintScreenState extends State<PvPSprintScreen> {
  String _gameState = 'waiting'; // waiting, matching, waiting-for-friend, room-countdown, racing, finished
  int _roomCountdown = 5;
  dynamic _racePhase = 'ready'; // 'ready', 3, 2, 1, 'go', 'running'
  double _myProgress = 0;
  double _opponentProgress = 0;
  String _opponentName = '';

  List<IncomingChallengeMock> _incomingList = List.from(mockIncomingChallenges);

  Timer? _stateTimer;
  Timer? _raceTimer;

  @override
  void dispose() {
    _stateTimer?.cancel();
    _raceTimer?.cancel();
    super.dispose();
  }

  void _startMatchmaking() {
    setState(() {
      _gameState = 'matching';
    });
    _stateTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _opponentName = 'LuminaMaster99';
        _gameState = 'room-countdown';
      });
      _startRoomCountdown();
    });
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

  void _acceptChallenge(int id, String name) {
    setState(() {
      _incomingList.removeWhere((c) => c.id == id);
      _opponentName = name;
      _gameState = 'room-countdown';
    });
    _startRoomCountdown();
  }

  void _rejectChallenge(int id) {
    setState(() {
      _incomingList.removeWhere((c) => c.id == id);
    });
  }

  void _cancelInvite() {
    _stateTimer?.cancel();
    setState(() {
      _gameState = 'waiting';
      _opponentName = '';
    });
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
    return Stack(
      children: [
        // Background mapping based on state
        if (_gameState == 'waiting' || _gameState == 'matching' || _gameState == 'waiting-for-friend' || _gameState == 'room-countdown')
          _buildWaitingRoom()
        else
          PvPRacingEnvironment(
            isMoving: _gameState == 'racing' && _racePhase == 'running',
            myProgress: _myProgress,
            opponentProgress: _opponentProgress,
            opponentName: _opponentName,
            racePhase: _racePhase.toString(),
            isFinished: _gameState == 'finished',
            onClose: _resetGame,
          ),

        // Overlays
        if (_gameState == 'matching') PvPMatchingOverlay(),
        if (_gameState == 'waiting-for-friend') PvPWaitingFriendOverlay(opponentName: _opponentName, onCancel: _cancelInvite),
        if (_gameState == 'room-countdown') PvPRoomCountdownOverlay(opponentName: _opponentName, countdown: _roomCountdown),
        if (_gameState == 'finished') PvPFinishedOverlay(
          isWin: _myProgress >= 100,
          opponentName: _opponentName,
          onContinue: _resetGame,
        ),
      ],
    );
  }

  Widget _buildWaitingRoom() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => showIncomingChallengesModal(context, _incomingList, _acceptChallenge, _rejectChallenge),
                    icon: const Icon(Icons.mail),
                  ),
                  if (_incomingList.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('${_incomingList.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: () => showMatchHistoryModal(context, mockMatchHistory),
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pet Avatar Placeholder
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(Icons.pets, size: 80, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('Mochi (Cấp 15)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          _buildStatRow('Bước đi hôm nay:', '4,500', theme),
                          const SizedBox(height: 8),
                          _buildStatRow('Hệ tinh linh:', 'Thực Vật', theme),
                          const SizedBox(height: 8),
                          _buildStatRow('Năng lượng:', '100/100', theme),
                          const SizedBox(height: 8),
                          _buildStatRow('Độ gắn kết:', '850', theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _gameState == 'waiting' ? _startMatchmaking : null,
              icon: const Icon(Icons.sports_kabaddi),
              label: const Text('Ghép trận ngẫu nhiên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _gameState == 'waiting' ? () => showFriendsModal(context, mockOnlineFriends, mockOfflineFriends, _inviteFriend) : null,
              icon: const Icon(Icons.people),
              label: const Text('Thách đấu với bạn bè', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 100), // spacing for bottom bar if any
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
