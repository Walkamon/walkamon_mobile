import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/motion/game_presentation_coordinator.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/theme/app_colors.dart';
import '../common/game_notice_host.dart';
import 'level_up_overlay.dart';
import 'nine_slice_game_frame.dart';

class GameRewardEntry {
  const GameRewardEntry({required this.name, required this.quantity});
  final String name;
  final int quantity;
}

/// Cosmetic only: real wallet/inventory must already be reconciled by caller.
class GameRewardPresentation {
  const GameRewardPresentation({
    required this.id,
    required this.message,
    this.items = const [],
  });
  final String id;
  final String message;
  final List<GameRewardEntry> items;
}

class GamePresentationHost extends StatefulWidget {
  const GamePresentationHost({super.key, required this.child, this.sessionKey});
  final Widget child;
  final String? sessionKey;

  static bool showLevelUp(
    BuildContext context, {
    required String id,
    required int before,
    required int after,
  }) =>
      context.findAncestorStateOfType<_GamePresentationHostState>()?._showLevel(
        context,
        id,
        before,
        after,
      ) ??
      false;

  static bool showReward(BuildContext context, GameRewardPresentation reward) {
    final host = context.findAncestorStateOfType<_GamePresentationHostState>();
    if (host == null) {
      GameNoticeHost.show(reward.message, type: GameNoticeType.reward);
      return false;
    }
    return host._show(context, reward);
  }

  @override
  State<GamePresentationHost> createState() => _GamePresentationHostState();
}

class _GamePresentationHostState extends State<GamePresentationHost>
    with WidgetsBindingObserver {
  final _coordinator = GamePresentationCoordinator();
  GameRewardPresentation? _reward;
  ModalRoute<dynamic>? _source;
  Timer? _timer;
  bool _foreground = true;
  (int, int)? _level;

  bool _showLevel(BuildContext source, String id, int before, int after) {
    final route = ModalRoute.of(source);
    if (!_foreground || route?.isCurrent == false || after <= before) {
      return false;
    }
    if (_coordinator.active != null) return false;
    if (!_coordinator.begin(id)) return false;
    _source = route;
    route?.animation?.addStatusListener(_routeStatus);
    route?.secondaryAnimation?.addStatusListener(_routeStatus);
    setState(() => _level = (before, after));
    _timer = Timer(
      MotionTokens.levelUp + const Duration(milliseconds: 300),
      _dismiss,
    );
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool _show(BuildContext source, GameRewardPresentation reward) {
    final route = ModalRoute.of(source);
    if (!_foreground || (route != null && !route.isCurrent)) return false;
    if (!_coordinator.begin(reward.id)) return false;
    _source = route;
    route?.animation?.addStatusListener(_routeStatus);
    route?.secondaryAnimation?.addStatusListener(_routeStatus);
    setState(() => _reward = reward);
    // Keep text readable after the 950ms reveal. No backlog on resume.
    _timer = Timer(const Duration(milliseconds: 2600), _dismiss);
    return true;
  }

  void _routeStatus(AnimationStatus _) {
    if (_source?.isCurrent == false) _dismiss();
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _source?.animation?.removeStatusListener(_routeStatus);
    _source?.secondaryAnimation?.removeStatusListener(_routeStatus);
    _source = null;
    _coordinator.finish();
    if (mounted && (_reward != null || _level != null)) {
      setState(() {
        _reward = null;
        _level = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant GamePresentationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionKey != widget.sessionKey) {
      _dismiss();
      _coordinator.reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _dismiss();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _source?.animation?.removeStatusListener(_routeStatus);
    _source?.secondaryAnimation?.removeStatusListener(_routeStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (_level case final level?)
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 88,
          child: Center(
            child: LevelUpOverlay(
              before: level.$1,
              after: level.$2,
              onDismiss: _dismiss,
            ),
          ),
        ),
      if (_reward case final reward?)
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 88,
          child: Center(
            child: GameRewardOverlay(
              key: ValueKey(reward.id),
              reward: reward,
              onDismiss: _dismiss,
            ),
          ),
        ),
    ],
  );
}

class GameRewardOverlay extends StatelessWidget {
  const GameRewardOverlay({
    super.key,
    required this.reward,
    required this.onDismiss,
  });
  final GameRewardPresentation reward;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final reduced = MotionPolicy.of(context).reduced;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MotionPolicy.of(context).duration(MotionTokens.reward),
      curve: MotionTokens.settleCurve,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: reduced ? 1 : .96 + .04 * value,
          child: child,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: NineSliceGameFrame(
                asset: 'assets/Mobile/ui_frames/reward_result_9slice.png',
                slice: const Rect.fromLTWH(256, 320, 256, 256),
                child: Container(
                  width: 340,
                  constraints: BoxConstraints(
                    minHeight: 180,
                    maxHeight: (MediaQuery.sizeOf(context).height * .45).clamp(
                      180,
                      360,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(48, 72, 48, 32),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.woodDeep,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(reward.message, textAlign: TextAlign.center),
                          if (reward.items.isNotEmpty)
                            const SizedBox(height: 8),
                          ...reward.items.map(
                            (item) => Text(
                              '${item.name} ×${item.quantity}',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
