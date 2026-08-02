import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';

class HomePageBackdrop extends StatelessWidget {
  const HomePageBackdrop({super.key, required this.child});

  final Widget child;

  String _backgroundForAffinity(String affinityCode) {
    switch (affinityCode.trim().toLowerCase()) {
      case 'dawn':
        return AppAssets.homeDawn;
      case 'warm_sun':
        return AppAssets.homeWarmSun;
      case 'moonlight':
        return AppAssets.homeMoonlight;
      default:
        return AppAssets.homeSprout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final affinityCode = context.select<GameStateProvider, String>(
      (state) => state.affinityCode,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _backgroundForAffinity(affinityCode),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
          ),
        ),
        ColoredBox(
          color: isDark
              ? Colors.black.withValues(alpha: 0.28)
              : AppColors.authCard.withValues(alpha: 0.18),
        ),
        child,
      ],
    );
  }
}
