import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../widgets/pet_runtime/pet_production_game.dart';
import '../../widgets/pet_runtime/pet_renderer_host.dart';
import '../../widgets/pet_runtime/pet_runtime_models.dart';

/// Longest production hello clip is 2.58 s (Dawn Stage 2). The remaining
/// 120 ms covers timer/frame quantization without showing the resolved state
/// under a stale Hello label.
@visibleForTesting
const petAnimationPlayerHelloHold = Duration(milliseconds: 2700);

class PetAnimationPlayerScreen extends StatefulWidget {
  const PetAnimationPlayerScreen({super.key});

  @override
  State<PetAnimationPlayerScreen> createState() =>
      _PetAnimationPlayerScreenState();
}

class _PetAnimationPlayerScreenState extends State<PetAnimationPlayerScreen> {
  static const _forms = <String, ({String affinity, int stage})>{
    'Sprout': (affinity: 'sprout', stage: 0),
    'Warm Sun · Stage 1': (affinity: 'warm_sun', stage: 1),
    'Warm Sun · Stage 2': (affinity: 'warm_sun', stage: 2),
    'Dawn · Stage 1': (affinity: 'dawn', stage: 1),
    'Dawn · Stage 2': (affinity: 'dawn', stage: 2),
    'Moonlight · Stage 1': (affinity: 'moonlight', stage: 1),
    'Moonlight · Stage 2': (affinity: 'moonlight', stage: 2),
  };

  static const _playAllStates = <({PetSemanticState state, Duration hold})>[
    (state: PetSemanticState.idle, hold: Duration(milliseconds: 2200)),
    (state: PetSemanticState.happy, hold: Duration(milliseconds: 3400)),
    (state: PetSemanticState.idle, hold: Duration(milliseconds: 1400)),
    (state: PetSemanticState.hungry, hold: Duration(milliseconds: 4200)),
    (state: PetSemanticState.feedEat, hold: Duration(milliseconds: 6200)),
    (state: PetSemanticState.sad, hold: Duration(milliseconds: 4200)),
    (state: PetSemanticState.tapHello, hold: petAnimationPlayerHelloHold),
    (state: PetSemanticState.excited, hold: Duration(milliseconds: 4200)),
    (state: PetSemanticState.idle, hold: Duration(milliseconds: 1400)),
    (state: PetSemanticState.sleep, hold: Duration(milliseconds: 6200)),
    (state: PetSemanticState.idle, hold: Duration(milliseconds: 3200)),
  ];

  String _formLabel = 'Moonlight · Stage 1';
  PetSemanticState _selectedState = PetSemanticState.idle;
  int _actionSerial = 0;
  Timer? _playAllTimer;
  int _playAllIndex = 0;
  bool _isPlayingAll = false;
  bool _paused = false;
  double _speed = 1;
  PetProductionGame? _game;

  PetRuntimeInput get _input {
    final form = _forms[_formLabel]!;
    return PetRuntimeInput(
      affinityCode: form.affinity,
      stageNo: form.stage,
      state: _selectedState,
      actionSerial: _actionSerial,
    );
  }

  void _selectState(PetSemanticState state) {
    setState(() {
      _selectedState = state;
      if (state.isAction) _actionSerial++;
    });
  }

  void _togglePlayAll() {
    if (_isPlayingAll) {
      _stopPlayAll();
      return;
    }
    setState(() {
      _isPlayingAll = true;
      _playAllIndex = 0;
    });
    _advancePlayAll();
  }

  void _advancePlayAll() {
    if (!mounted || !_isPlayingAll) return;
    if (_playAllIndex >= _playAllStates.length) {
      setState(() => _isPlayingAll = false);
      return;
    }
    final step = _playAllStates[_playAllIndex];
    _selectState(step.state);
    _playAllTimer = Timer(step.hold, () {
      _playAllIndex++;
      _advancePlayAll();
    });
  }

  void _stopPlayAll() {
    _playAllTimer?.cancel();
    _playAllTimer = null;
    if (!mounted) return;
    setState(() {
      _isPlayingAll = false;
      _selectedState = PetSemanticState.idle;
    });
  }

  @override
  void dispose() {
    _playAllTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Pet Animation Player')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: SizedBox.square(
                dimension: 300,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x303B4674),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: PetRendererHost(
                    input: _input,
                    showDebugOverlay: true,
                    onGameCreated: (game) => _game = game,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _formLabel,
              decoration: const InputDecoration(labelText: 'Form / stage'),
              items: [
                for (final label in _forms.keys)
                  DropdownMenuItem(value: label, child: Text(label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                _stopPlayAll();
                setState(() => _formLabel = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PetSemanticState>(
              initialValue: _selectedState,
              decoration: const InputDecoration(labelText: 'Semantic state'),
              items: [
                for (final state in PetSemanticState.values)
                  DropdownMenuItem(value: state, child: Text(state.wireName)),
              ],
              onChanged: (value) {
                if (value == null) return;
                _stopPlayAll();
                _selectState(value);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey('pet-player-play-selected'),
                  onPressed: () => _selectState(_selectedState),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('PHÁT STATE'),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('pet-player-play-all'),
                  onPressed: _togglePlayAll,
                  icon: Icon(_isPlayingAll ? Icons.stop : Icons.playlist_play),
                  label: Text(_isPlayingAll ? 'DỪNG' : 'PHÁT TẤT CẢ'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _paused = !_paused);
                    _game?.setPaused(_paused);
                  },
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                  label: Text(_paused ? 'TIẾP TỤC' : 'TẠM DỪNG'),
                ),
                OutlinedButton(
                  onPressed: () => _game?.stepFrame(-1),
                  child: const Text('KHUNG TRƯỚC'),
                ),
                OutlinedButton(
                  onPressed: () => _game?.stepFrame(1),
                  child: const Text('KHUNG SAU'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0.5, label: Text('0.5×')),
                ButtonSegment(value: 1.0, label: Text('1.0×')),
              ],
              selected: {_speed},
              onSelectionChanged: (selection) {
                final speed = selection.first;
                setState(() => _speed = speed);
                _game?.setPlaybackSpeed(speed);
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Giữ lâu trên pet ở Home để mở màn hình này trong debug build. '
              'PHÁT TẤT CẢ luôn bấm được; bấm lần nữa để dừng.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
