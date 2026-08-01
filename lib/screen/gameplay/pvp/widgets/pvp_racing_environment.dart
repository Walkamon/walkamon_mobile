import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../widgets/common/app_icon.dart';
import '../../../../widgets/pet_runtime/pet_runtime_preview.dart';
import '../pvp_asset_resolver.dart';
import 'pvp_frame_animation.dart';
import 'pvp_two_slot_hud.dart';

class PvPRacingEnvironment extends StatefulWidget {
  final bool isMoving;
  final double myProgress;
  final double opponentProgress;
  final String opponentName;
  final String racePhase;
  final bool isFinished;
  final FutureOr<void> Function() onClose;
  final String mapAsset;
  final String myAffinityCode;
  final String opponentAffinityCode;
  final int myStageNo;
  final int opponentStageNo;
  final List<String> myActiveEffects;
  final List<String> opponentActiveEffects;
  final PvpHudSlot leftSlot;
  final PvpHudSlot rightSlot;

  const PvPRacingEnvironment({
    super.key,
    required this.isMoving,
    required this.myProgress,
    required this.opponentProgress,
    required this.opponentName,
    required this.racePhase,
    required this.isFinished,
    required this.onClose,
    required this.mapAsset,
    this.myAffinityCode = 'sprout',
    this.opponentAffinityCode = 'sprout',
    this.myStageNo = 0,
    this.opponentStageNo = 0,
    this.myActiveEffects = const <String>[],
    this.opponentActiveEffects = const <String>[],
    this.leftSlot = const PvpHudSlot(itemCode: 'haste'),
    this.rightSlot = const PvpHudSlot(itemCode: 'shield'),
  });

  @override
  State<PvPRacingEnvironment> createState() => _PvPRacingEnvironmentState();
}

class _PvPRacingEnvironmentState extends State<PvPRacingEnvironment>
    with SingleTickerProviderStateMixin {
  late AnimationController _parallaxController;

  @override
  void initState() {
    super.initState();
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.isMoving) {
      _parallaxController.repeat();
    }
  }

  @override
  void didUpdateWidget(PvPRacingEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving && !oldWidget.isMoving) {
      _parallaxController.repeat();
    } else if (!widget.isMoving && oldWidget.isMoving) {
      _parallaxController.stop();
    }
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    super.dispose();
  }

  bool get _shouldShowCountdown {
    if (widget.isFinished) return false;
    final phase = widget.racePhase.toLowerCase();
    if (phase == 'ready' || phase == 'running' || phase == 'finished') {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _parallaxController,
          builder: (context, _) {
            final shift = widget.isMoving
                ? -(_parallaxController.value * width * 0.35)
                : 0.0;
            return Transform.translate(
              offset: Offset(shift, 0),
              child: SizedBox(
                width: width * 1.35,
                height: double.infinity,
                child: Image.asset(
                  widget.mapAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.35),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 110 + bottomInset,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.42,
          child: Column(
            children: [
              Expanded(
                child: _Lane(
                  progress: widget.opponentProgress,
                  width: width,
                  label: widget.opponentName,
                  labelColor: theme.colorScheme.surface,
                  labelTextColor: theme.colorScheme.onSurface,
                  affinityCode: widget.opponentAffinityCode,
                  stageNo: widget.opponentStageNo,
                  petSize: 72,
                  activeEffects: widget.opponentActiveEffects,
                  isMoving: widget.isMoving,
                ),
              ),
              Expanded(
                child: _Lane(
                  progress: widget.myProgress,
                  width: width,
                  label: 'Bạn',
                  labelColor: theme.colorScheme.primary,
                  labelTextColor: theme.colorScheme.onPrimary,
                  affinityCode: widget.myAffinityCode,
                  stageNo: widget.myStageNo,
                  petSize: 84,
                  activeEffects: widget.myActiveEffects,
                  isMoving: widget.isMoving,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: widget.onClose,
                    icon: const AppIcon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SPRINT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: (widget.myProgress / 100) * (width - 160),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width:
                                (widget.opponentProgress / 100) * (width - 160),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + bottomInset,
          child: PvpTwoSlotHud(left: widget.leftSlot, right: widget.rightSlot),
        ),
        if (_shouldShowCountdown)
          Center(
            child: Text(
              widget.racePhase.toUpperCase(),
              style: TextStyle(
                fontSize: widget.racePhase == 'go' ? 110 : 120,
                fontWeight: FontWeight.bold,
                color: widget.racePhase == 'go' ? Colors.amber : Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.progress,
    required this.width,
    required this.label,
    required this.labelColor,
    required this.labelTextColor,
    required this.affinityCode,
    required this.stageNo,
    required this.petSize,
    required this.activeEffects,
    required this.isMoving,
  });

  final double progress;
  final double width;
  final String label;
  final Color labelColor;
  final Color labelTextColor;
  final String affinityCode;
  final int stageNo;
  final double petSize;
  final List<String> activeEffects;
  final bool isMoving;

  @override
  Widget build(BuildContext context) {
    final effect = activeEffects.isNotEmpty ? activeEffects.first : null;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Positioned(
          left: 12,
          right: 12,
          child: Container(height: 2, color: Colors.white.withOpacity(0.28)),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 100),
          left: 16 + (progress / 100) * (width - 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: labelColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: labelTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: petSize + 24,
                height: petSize + 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (effect != null)
                      PvpFrameAnimation(
                        effectCode: effect,
                        width: petSize + 24,
                        height: petSize + 24,
                        playing: isMoving || progress > 0,
                      ),
                    PetRuntimePreview(
                      affinityCode: affinityCode,
                      stageNo: stageNo,
                      animationType: isMoving ? 'excited' : 'idle',
                      compact: true,
                      height: petSize,
                    ),
                    if (effect != null) ...[
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Image.asset(
                          PvpAssetResolver.statusIcon(effect) ??
                              PvpAssetResolver.itemIcon(effect) ??
                              AppAssets.pvpHasteStatus,
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
