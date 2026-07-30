import 'package:flutter/material.dart';
import 'dart:async';

class PvPRacingEnvironment extends StatefulWidget {
  final bool isMoving;
  final double myProgress;
  final double opponentProgress;
  final String opponentName;
  final String racePhase;
  final bool isFinished;
  final FutureOr<void> Function() onClose;

  const PvPRacingEnvironment({
    super.key,
    required this.isMoving,
    required this.myProgress,
    required this.opponentProgress,
    required this.opponentName,
    required this.racePhase,
    required this.isFinished,
    required this.onClose,
  });

  @override
  State<PvPRacingEnvironment> createState() => _PvPRacingEnvironmentState();
}

class _PvPRacingEnvironmentState extends State<PvPRacingEnvironment> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.isMoving) {
      _bgController.repeat();
    }
  }

  @override
  void didUpdateWidget(PvPRacingEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving && !oldWidget.isMoving) {
      _bgController.repeat();
    } else if (!widget.isMoving && oldWidget.isMoving) {
      _bgController.stop();
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  bool get _shouldShowCountdown {
    if (widget.isFinished) return false;
    final phase = widget.racePhase.toLowerCase();
    if (phase == 'ready' || phase == 'running' || phase == 'finished') {
      return false;
    }
    // "5".."1" or "go"
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
        Container(color: Colors.lightBlue.shade100),
        AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
            return Positioned(
              left: -(_bgController.value * width),
              top: 0,
              width: width * 2,
              child: Row(
                children: [
                  _buildCloudLayer(width),
                  _buildCloudLayer(width),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Container(color: Colors.green.shade600),
        ),
        AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
            return Positioned(
              bottom: 0,
              left: -(_bgController.value * width),
              width: width * 2,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Row(
                children: [
                  _buildTrackSegment(width),
                  _buildTrackSegment(width),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.4,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        top: 25,
                        left: 0,
                        right: 0,
                        child: Container(height: 2, color: Colors.white.withOpacity(0.3)),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeIn,
                        left: widget.isMoving || widget.myProgress > 0 || widget.opponentProgress > 0 ? -100.0 : 80.0,
                        top: 25,
                        bottom: 0,
                        child: Container(width: 10, color: Colors.white),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(seconds: 1),
                        curve: Curves.linear,
                        right: (widget.myProgress > 95 || widget.opponentProgress > 95) ? 60.0 : -100.0,
                        top: 25,
                        bottom: 0,
                        child: Container(width: 15, color: Colors.amber),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        left: 18 + (widget.opponentProgress / 100) * (width - 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Text(widget.opponentName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 4),
                            Icon(Icons.pets, size: 48, color: Colors.red.shade300),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 2)),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeIn,
                        left: widget.isMoving || widget.myProgress > 0 || widget.opponentProgress > 0 ? -100.0 : 80.0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 10, color: Colors.white),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(seconds: 1),
                        curve: Curves.linear,
                        right: (widget.myProgress > 95 || widget.opponentProgress > 95) ? 60.0 : -100.0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 15, color: Colors.amber),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        left: 20 + (widget.myProgress / 100) * (width - 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Bạn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)),
                            ),
                            const SizedBox(height: 4),
                            Icon(Icons.pets, size: 56, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            width: (widget.opponentProgress / 100) * (width - 160),
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

  Widget _buildCloudLayer(double width) {
    return SizedBox(
      width: width,
      height: 200,
      child: Stack(
        children: const [
          Positioned(top: 20, left: 40, child: Icon(Icons.cloud, size: 80, color: Colors.white70)),
          Positioned(top: 60, left: 200, child: Icon(Icons.cloud, size: 120, color: Colors.white54)),
          Positioned(top: 10, left: 300, child: Icon(Icons.cloud, size: 60, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildTrackSegment(double width) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.grass, color: Colors.white30, size: 24),
                Icon(Icons.grass, color: Colors.white24, size: 18),
                Icon(Icons.grass, color: Colors.white30, size: 28),
                Icon(Icons.grass, color: Colors.white24, size: 20),
                Icon(Icons.grass, color: Colors.white30, size: 24),
                Icon(Icons.grass, color: Colors.white24, size: 18),
                Icon(Icons.grass, color: Colors.white30, size: 22),
              ],
            ),
          ),
          Positioned(top: 18, left: 40, child: Icon(Icons.eco, size: 28, color: Colors.green.shade700)),
          Positioned(top: 20, left: 190, child: Icon(Icons.eco, size: 22, color: Colors.green.shade800)),
          Positioned(top: 16, left: 390, child: Icon(Icons.eco, size: 30, color: Colors.green.shade700)),
          Positioned(top: 20, left: 540, child: Icon(Icons.eco, size: 24, color: Colors.green.shade800)),
          Positioned(top: 0, left: 70, child: Icon(Icons.park, size: 80, color: Colors.green.shade900)),
          Positioned(top: 0, left: 280, child: Icon(Icons.park, size: 95, color: Colors.green.shade800)),
          Positioned(top: 0, left: 490, child: Icon(Icons.park, size: 75, color: Colors.green.shade900)),
        ],
      ),
    );
  }
}