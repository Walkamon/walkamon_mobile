import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Reusable tutorial layer which measures an existing real control by key.
/// The highlighted hit target invokes the same callback as the underlying UI.
class TutorialSpotlightOverlay extends StatefulWidget {
  const TutorialSpotlightOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    required this.stepLabel,
    required this.skipLabel,
    required this.onSkip,
    this.targetSemanticLabel,
    this.onTargetTap,
    this.onNext,
    this.nextLabel,
    this.targetPadding = 10,
    this.blockOutsideTouches = true,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final String stepLabel;
  final String skipLabel;
  final FutureOr<void> Function() onSkip;
  final String? targetSemanticLabel;
  final FutureOr<void> Function()? onTargetTap;
  final FutureOr<void> Function()? onNext;
  final String? nextLabel;
  final double targetPadding;
  final bool blockOutsideTouches;

  @override
  State<TutorialSpotlightOverlay> createState() =>
      _TutorialSpotlightOverlayState();
}

class _TutorialSpotlightOverlayState extends State<TutorialSpotlightOverlay> {
  final GlobalKey _overlayKey = GlobalKey();
  Rect? _targetRect;
  bool _scheduled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant TutorialSpotlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey ||
        oldWidget.title != widget.title) {
      _targetRect = null;
    }
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final target = widget.targetKey.currentContext?.findRenderObject();
      final overlay = _overlayKey.currentContext?.findRenderObject();
      if (target is! RenderBox || overlay is! RenderBox || !target.hasSize) {
        _scheduleMeasure();
        return;
      }
      final global = target.localToGlobal(Offset.zero);
      final local = overlay.globalToLocal(global);
      final rect = (local & target.size).inflate(widget.targetPadding);
      if (_targetRect != rect) setState(() => _targetRect = rect);
    });
  }

  Future<void> _invoke(FutureOr<void> Function()? action) async {
    if (_busy || action == null) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect;
    _scheduleMeasure();
    return Positioned.fill(
      child: Semantics(
        container: true,
        label: '${widget.stepLabel}. ${widget.title}. ${widget.description}',
        child: Stack(
          key: _overlayKey,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.blockOutsideTouches ? () {} : null,
                child: CustomPaint(
                  painter: _TutorialSpotlightPainter(targetRect: target),
                ),
              ),
            ),
            if (target != null && widget.onTargetTap != null)
              Positioned.fromRect(
                rect: target,
                child: Semantics(
                  button: true,
                  label: widget.targetSemanticLabel ?? widget.title,
                  child: GestureDetector(
                    key: const ValueKey('tutorial-real-target'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _busy ? null : () => _invoke(widget.onTargetTap),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            _TutorialCard(
              targetRect: target,
              title: widget.title,
              description: widget.description,
              stepLabel: widget.stepLabel,
              skipLabel: widget.skipLabel,
              nextLabel: widget.nextLabel,
              busy: _busy,
              onSkip: () => _invoke(widget.onSkip),
              onNext: widget.onNext == null
                  ? null
                  : () => _invoke(widget.onNext),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.stepLabel,
    required this.skipLabel,
    required this.nextLabel,
    required this.busy,
    required this.onSkip,
    required this.onNext,
  });

  final Rect? targetRect;
  final String title;
  final String description;
  final String stepLabel;
  final String skipLabel;
  final String? nextLabel;
  final bool busy;
  final VoidCallback onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final showBelow =
        targetRect == null || targetRect!.center.dy < size.height * .48;
    final maxWidth = (size.width - 32).clamp(260.0, 420.0);
    return Positioned(
      left: 16,
      right: 16,
      top: showBelow ? null : 16,
      bottom: showBelow ? 20 : null,
      child: SafeArea(
        child: Align(
          alignment: showBelow ? Alignment.bottomCenter : Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: AppColors.authCard,
              elevation: 10,
              shadowColor: AppColors.woodDeep.withValues(alpha: .32),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.woodDeep, width: 1.6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepLabel,
                      style: const TextStyle(
                        color: AppColors.oliveDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.woodDeep,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.inkBrown,
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: busy ? null : onSkip,
                          child: Text(
                            skipLabel,
                            style: const TextStyle(fontFamily: 'Quicksand'),
                          ),
                        ),
                        if (onNext != null) ...[
                          FilledButton(
                            onPressed: busy ? null : onNext,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(88, 44),
                              backgroundColor: AppColors.buttonGreen,
                              foregroundColor: AppColors.woodDeep,
                            ),
                            child: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    nextLabel ?? '',
                                    style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  const _TutorialSpotlightPainter({required this.targetRect});

  final Rect? targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = const Color(0xB2142118);
    final path = Path()..addRect(Offset.zero & size);
    if (targetRect != null) {
      path.addRRect(
        RRect.fromRectAndRadius(targetRect!, const Radius.circular(20)),
      );
      path.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, overlay);
    if (targetRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect!, const Radius.circular(20)),
        Paint()
          ..color = const Color(0xFFFFE79B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}
