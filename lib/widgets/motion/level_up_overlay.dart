import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'lumina_vfx_layer.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({
    super.key,
    required this.before,
    required this.after,
    required this.onDismiss,
  });
  final int before;
  final int after;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final policy = MotionPolicy.of(context);
    final l10n = AppLocalizations.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: policy.duration(MotionTokens.levelUp),
      builder: (context, t, _) => Semantics(
        liveRegion: true,
        label: '${l10n.levelShort(before)} → ${l10n.levelShort(after)}',
        child: Material(
          color: AppColors.authCard,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: t >= .37 || policy.reduced ? onDismiss : null,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 280,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: LuminaVfxLayer(progress: t)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppAssets.iconUpgrade, width: 40, height: 40),
                      const SizedBox(height: 8),
                      Text(
                        l10n.levelShort(
                          t < .37 && !policy.reduced ? before : after,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.woodDeep,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
