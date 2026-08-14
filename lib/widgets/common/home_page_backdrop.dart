import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';

class HomePageBackdrop extends StatelessWidget {
  const HomePageBackdrop({super.key, required this.child});

  final Widget child;

  String _backgroundForAffinity(String affinityCode, bool isDark) {
    switch (affinityCode.trim().toLowerCase()) {
      case 'sprout':
      case 'mam_non':
        return isDark ? AppAssets.homeSproutDark : AppAssets.homeSprout;
      case 'dawn':
      case 'binh_minh':
        return isDark ? AppAssets.homeDawnDark : AppAssets.homeDawn;
      case 'warm_sun':
      case 'nang_am':
        return isDark ? AppAssets.homeWarmSunDark : AppAssets.homeWarmSun;
      case 'moonlight':
      case 'anh_trang':
        return isDark ? AppAssets.homeMoonlight : AppAssets.homeMoonlightLight;
      default:
        return isDark ? AppAssets.homeSproutDark : AppAssets.homeSprout;
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
          _backgroundForAffinity(affinityCode, isDark),
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
              ? Colors.black.withValues(alpha: 0.18)
              : AppColors.authCard.withValues(alpha: 0.18),
        ),
        child,
      ],
    );
  }
}
