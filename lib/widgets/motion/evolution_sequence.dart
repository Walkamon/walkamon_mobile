import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/motion/motion_tokens.dart';
import '../../data/models/pet_evolution_models.dart';
import '../../l10n/app_localizations.dart';
import '../pet_runtime/pet_runtime_preview.dart';
import '../pet_runtime/pet_production_game.dart';
import 'lumina_vfx_layer.dart';

/// Only mounted after a committed response and a refreshed, confirmed form.
/// It owns no repository and cannot repeat an evolution request on skip/resume.
class EvolutionSequence extends StatefulWidget {
  const EvolutionSequence({
    super.key,
    required this.before,
    required this.after,
  });
  final PetOverviewResponse before;
  final PetOverviewResponse after;
  @override
  State<EvolutionSequence> createState() => _EvolutionSequenceState();
}

class _EvolutionSequenceState extends State<EvolutionSequence>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _started = false;
  bool _closed = false;
  PetProductionGame? _targetGame;
  Timer? _loadDeadline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller =
        AnimationController(vsync: this, duration: MotionTokens.evolution)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _close();
          });
    _loadDeadline = Timer(const Duration(seconds: 8), _close);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started && MotionPolicy.of(context).reduced) {
      _controller.duration = MotionTokens.reduced;
    }
  }

  void _targetCreated(PetProductionGame game) {
    _targetGame = game;
    game.debugInfo.addListener(_targetReady);
  }

  void _targetReady() {
    if (!mounted || _started || _targetGame!.currentDebugInfo.frameCount == 0) {
      return;
    }
    _targetGame!.debugInfo.removeListener(_targetReady);
    _loadDeadline?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closed) return;
      setState(() => _started = true);
      _controller.duration = MotionPolicy.of(
        context,
      ).duration(MotionTokens.evolution);
      _controller.forward();
    });
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    // Never pop another route if a notification/deep link covered this one.
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _close();
  }

  @override
  void dispose() {
    _loadDeadline?.cancel();
    _targetGame?.debugInfo.removeListener(_targetReady);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Widget _pet(PetOverviewResponse pet, String animation) => PetRuntimePreview(
    affinityCode: pet.affinityCode,
    stageNo: pet.stageNo,
    animationType: animation,
    compact: true,
    height: 280,
    onGameCreated: identical(pet, widget.after) ? _targetCreated : null,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduced = MotionPolicy.of(context).reduced;
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.97),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final reveal = reduced && _started
                    ? 1.0
                    : ((t - 0.47) / 0.15).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reveal < 1
                            ? l10n.spiritEvolving
                            : widget.after.formName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Both renderers load in parallel, so reveal does not start a new decode.
                            Opacity(
                              opacity: 1 - reveal,
                              child: _pet(widget.before, 'idle'),
                            ),
                            Opacity(
                              opacity: reveal,
                              child: _pet(widget.after, 'happy'),
                            ),
                            Positioned.fill(child: LuminaVfxLayer(progress: t)),
                          ],
                        ),
                      ),
                      if (!_started)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      TextButton(
                        onPressed: _close,
                        child: Text(
                          MaterialLocalizations.of(context).closeButtonLabel,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
