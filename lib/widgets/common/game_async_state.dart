import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

class GameLoadingIndicator extends StatefulWidget {
  const GameLoadingIndicator({super.key, this.size = 54, this.label});

  final double size;
  final String? label;

  @override
  State<GameLoadingIndicator> createState() => _GameLoadingIndicatorState();
}

class _GameLoadingIndicatorState extends State<GameLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkForeground
        : AppColors.woodDeep;
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _controller.value * math.pi * 2,
              child: child,
            ),
            child: Image.asset(
              AppAssets.iconMagicOrb,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  AppIcon(Icons.auto_awesome, size: widget.size, color: color),
            ),
          ),
          if (widget.label case final label? when label.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class GameAsyncStatePanel extends StatelessWidget {
  const GameAsyncStatePanel({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final background = isDark ? AppColors.darkCard : AppColors.authCard;
    final asset = isError ? AppAssets.iconErrorSystem : AppAssets.iconMagicOrb;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.wood,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                asset,
                width: 62,
                height: 62,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => AppIcon(
                  isError ? Icons.error_outline : Icons.inbox_outlined,
                  size: 58,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              if (onRetry != null && retryLabel != null) ...[
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const AppIcon(Icons.refresh, size: 20),
                  label: Text(retryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
