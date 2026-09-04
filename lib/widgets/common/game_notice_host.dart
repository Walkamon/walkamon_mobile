import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/feedback/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

/// Transient feedback placement. The host owns placement so screens do not
/// need to guess a safe `top` offset that may cover their HUD.
enum GameNoticeRegion { generic, home, pvpLobby, pvpRace, shop }

enum GameNoticeType { reward, success, error, warning, info }

class GameNoticeHost extends StatefulWidget {
  const GameNoticeHost({super.key, required this.child});

  final Widget child;

  static final GlobalKey<GameNoticeHostState> globalKey =
      GlobalKey<GameNoticeHostState>();

  static void show(
    String message, {
    GameNoticeType type = GameNoticeType.info,
    GameNoticeRegion region = GameNoticeRegion.generic,
  }) {
    final value = message.trim();
    if (value.isEmpty) return;
    globalKey.currentState?._enqueue(
      _GameNotice(message: value, type: type, region: region),
    );
  }

  static void dismiss() => globalKey.currentState?._dismiss();

  @override
  State<GameNoticeHost> createState() => GameNoticeHostState();
}

class _GameNotice {
  const _GameNotice({
    required this.message,
    required this.type,
    required this.region,
  });

  final String message;
  final GameNoticeType type;
  final GameNoticeRegion region;
}

class GameNoticeHostState extends State<GameNoticeHost> {
  final List<_GameNotice> _queue = <_GameNotice>[];
  Timer? _timer;
  _GameNotice? _current;

  void _enqueue(_GameNotice notice) {
    if (_current?.message == notice.message && _current?.type == notice.type) {
      return;
    }
    if (_queue.any(
      (item) => item.message == notice.message && item.type == notice.type,
    )) {
      return;
    }
    if (_current == null) {
      _showNext(notice);
    } else if (_queue.length < 2) {
      setState(() => _queue.add(notice));
    }
  }

  void _showNext([_GameNotice? next]) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _current = next ?? (_queue.isEmpty ? null : _queue.removeAt(0));
    });
    final current = _current;
    if (current == null) return;
    _timer = Timer(_durationFor(current.type), _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    setState(() {
      _current = null;
    });
    if (_queue.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showNext();
      });
    }
  }

  Duration _durationFor(GameNoticeType type) => switch (type) {
    GameNoticeType.warning ||
    GameNoticeType.error => const Duration(milliseconds: 3500),
    GameNoticeType.reward ||
    GameNoticeType.success ||
    GameNoticeType.info => const Duration(milliseconds: 2200),
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _current;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (notice != null)
          _NoticePositioned(notice: notice, onDismiss: _dismiss),
      ],
    );
  }
}

class _NoticePositioned extends StatelessWidget {
  const _NoticePositioned({required this.notice, required this.onDismiss});

  final _GameNotice notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = switch (notice.region) {
      GameNoticeRegion.home => media.padding.top + 104,
      GameNoticeRegion.pvpLobby => media.padding.top + 92,
      GameNoticeRegion.generic => media.padding.top + 70,
      _ => null,
    };
    final bottom = top != null
        ? null
        : switch (notice.region) {
            GameNoticeRegion.pvpRace => media.padding.bottom + 112,
            GameNoticeRegion.shop => media.padding.bottom + 104,
            GameNoticeRegion.generic ||
            GameNoticeRegion.home ||
            GameNoticeRegion.pvpLobby => null,
          };
    return Positioned(
      left: 12,
      right: 12,
      top: top,
      bottom: bottom,
      child: Align(
        alignment: top != null ? Alignment.topCenter : Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${notice.type.name}:${notice.message}'),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 12),
              child: Transform.scale(
                scale: 0.96 + (0.04 * value),
                child: child,
              ),
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 312,
                minHeight: 64,
                maxHeight: 112,
              ),
              child: _NoticeCard(notice: notice),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _GameNotice notice;

  @override
  Widget build(BuildContext context) {
    final isReward = notice.type == GameNoticeType.reward;
    final isPositive = notice.type == GameNoticeType.success || isReward;
    final isError = notice.type == GameNoticeType.error;
    final color = isError ? AppColors.coral : AppColors.woodDeep;
    final icon = switch (notice.type) {
      GameNoticeType.reward => Icons.card_giftcard_rounded,
      GameNoticeType.success => Icons.check_circle_outline,
      GameNoticeType.error => Icons.error_outline,
      GameNoticeType.warning => Icons.warning_amber_rounded,
      GameNoticeType.info => Icons.info_outline,
    };
    return Semantics(
      liveRegion: true,
      label: notice.message,
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppAssets.toastFeedbackFrame,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Padding(
              // The frame has wide ornamental caps. Keep all glyphs and text
              // inside its plain cream centre at narrow phone widths.
              padding: const EdgeInsets.fromLTRB(42, 13, 38, 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    icon,
                    asset: isPositive
                        ? (isReward
                              ? AppAssets.notificationRewardClaim
                              : AppAssets.notificationSuccess)
                        : isError
                        ? AppAssets.notificationError
                        : notice.type == GameNoticeType.warning
                        ? AppAssets.notificationWarning
                        : AppAssets.notificationInfo,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      notice.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        height: 1.24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showGameNotice(
  String message, {
  GameNoticeType type = GameNoticeType.info,
  GameNoticeRegion region = GameNoticeRegion.generic,
}) {
  if (type == GameNoticeType.reward || type == GameNoticeType.success) {
    unawaited(AppHaptics.success());
  } else if (type == GameNoticeType.warning || type == GameNoticeType.error) {
    unawaited(AppHaptics.warning());
  }
  GameNoticeHost.show(message, type: type, region: region);
}
