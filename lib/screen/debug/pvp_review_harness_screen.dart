import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../gameplay/pvp/widgets/pvp_racing_environment.dart';

/// Debug-only deterministic review surface for route boundaries, seven pet
/// forms, item effects and finish reactions. It is never routed in release.
class PvpReviewHarnessScreen extends StatefulWidget {
  const PvpReviewHarnessScreen({super.key});

  @override
  State<PvpReviewHarnessScreen> createState() => _PvpReviewHarnessScreenState();
}

class _PvpReviewHarnessScreenState extends State<PvpReviewHarnessScreen> {
  static const _forms = <(String, int, String)>[
    ('sprout', 0, 'Sprout'),
    ('warm_sun', 1, 'Warm Sun 1'),
    ('warm_sun', 2, 'Warm Sun 2'),
    ('moonlight', 1, 'Moonlight 1'),
    ('moonlight', 2, 'Moonlight 2'),
    ('dawn', 1, 'Dawn 1'),
    ('dawn', 2, 'Dawn 2'),
  ];

  Timer? _timer;
  double _progress = 0;
  bool _night = false;
  bool _playing = false;
  double _speed = 1;
  int _formIndex = 0;
  String _outcome = 'race';
  String _effect = '';
  bool _geometry = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    _timer?.cancel();
    setState(() => _playing = !_playing);
    if (!_playing) return;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _progress += .1 * _speed / 30;
        if (_progress > 1) _progress = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'PvpReviewHarnessScreen must never ship in release.');
    final form = _forms[_formIndex];
    final maps = _night
        ? const [
            AppAssets.pvpMapNightStart,
            AppAssets.pvpMapNightLoop,
            AppAssets.pvpMapNightFinish,
          ]
        : const [
            AppAssets.pvpMapMorningStart,
            AppAssets.pvpMapMorningLoop,
            AppAssets.pvpMapMorningFinish,
          ];
    final finished = _outcome != 'race';
    return Scaffold(
      body: Stack(
        children: [
          PvPRacingEnvironment(
            isMoving: !finished,
            trackProgress: finished ? 1 : _progress,
            myProgress: finished ? 100 : _progress * 100,
            opponentProgress: finished ? 98 : _progress * 96,
            opponentName: 'QA Rival',
            racePhase: finished ? 'finished' : 'running',
            isFinished: false,
            showFinishReaction: finished,
            finishResultCode: finished ? _outcome : null,
            onClose: () => Navigator.maybePop(context),
            mapAssets: maps,
            myAffinityCode: form.$1,
            myStageNo: form.$2,
            opponentAffinityCode: 'warm_sun',
            opponentStageNo: 2,
            myAnimationState: _outcome,
            opponentAnimationState: _outcome == 'win'
                ? 'lose'
                : _outcome == 'lose'
                ? 'win'
                : 'race',
            myActiveEffects: _effect.isEmpty ? const [] : [_effect],
            debugShowGeometry: _geometry,
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.black.withValues(alpha: .74),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: _progress,
                        onChanged: (value) => setState(() {
                          _progress = value;
                          _outcome = 'race';
                        }),
                      ),
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        alignment: WrapAlignment.center,
                        children: [
                          _chip(_night ? 'Night' : 'Morning', () {
                            setState(() => _night = !_night);
                          }),
                          _chip(_playing ? 'Pause' : 'Play', _togglePlayback),
                          _chip('${_speed.toInt()}x', () {
                            setState(() => _speed = _speed == 1 ? 6 : 1);
                          }),
                          _chip(form.$3, () {
                            setState(
                              () =>
                                  _formIndex = (_formIndex + 1) % _forms.length,
                            );
                          }),
                          _chip('Win', () => setState(() => _outcome = 'win')),
                          _chip(
                            'Lose',
                            () => setState(() => _outcome = 'lose'),
                          ),
                          _chip(
                            _effect.isEmpty ? 'Effect' : _effect,
                            () => setState(() {
                              const effects = [
                                '',
                                'haste',
                                'slow',
                                'shield',
                                'cleanse',
                              ];
                              _effect =
                                  effects[(effects.indexOf(_effect) + 1) %
                                      effects.length];
                            }),
                          ),
                          _chip(
                            'Grid',
                            () => setState(() => _geometry = !_geometry),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 38,
      child: FilledButton.tonal(onPressed: onPressed, child: Text(label)),
    );
  }
}
