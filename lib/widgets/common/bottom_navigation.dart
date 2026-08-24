import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key, this.currentRoute});

  /// Normally inferred from [ModalRoute]. A fixed value is useful for
  /// deterministic visual regression captures of the selected state.
  final String? currentRoute;

  bool _isActive(String route, String? currentRoute) {
    if (route == '/social') {
      return currentRoute == '/social' || currentRoute == '/friends';
    }
    return currentRoute == route;
  }

  void _open(BuildContext context, String route, bool isActive) {
    if (isActive) return;
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute =
        this.currentRoute ?? ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.darkNavigationIcon
        : AppColors.lightNavigationIcon;
    final barColor = isDark
        ? AppColors.darkNavigation.withValues(alpha: 0.90)
        : AppColors.leafLight.withValues(alpha: 0.86);
    final selectedColor = isDark
        ? AppColors.darkNavigationActive.withValues(alpha: 0.48)
        : AppColors.leafBright.withValues(alpha: 0.48);

    final items = <({String route, String asset, IconData fallback})>[
      (
        route: '/social',
        asset: AppAssets.iconFriendsNav,
        fallback: Icons.groups_rounded,
      ),
      (
        route: '/pvp',
        asset: AppAssets.iconPvpBattle,
        fallback: Icons.sports_martial_arts_rounded,
      ),
      (
        route: '/home',
        asset: AppAssets.iconHomeNav,
        fallback: Icons.home_rounded,
      ),
      (
        route: '/inventory',
        asset: AppAssets.iconInventoryNav,
        fallback: Icons.backpack_rounded,
      ),
      (
        route: '/shop',
        asset: AppAssets.iconShopNav,
        fallback: Icons.storefront_rounded,
      ),
    ];
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final itemSize = (availableWidth / items.length).clamp(44.0, 56.0);
    final iconSize = (itemSize * 0.72).clamp(32.0, 41.0);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 4, 10, 9),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (isDark ? AppColors.darkBorder : AppColors.oliveDeep)
                .withValues(alpha: 0.72),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.woodDeep.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.map((item) {
            final active = _isActive(item.route, currentRoute);
            return Semantics(
              button: true,
              selected: active,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _open(context, item.route, active),
                child: AnimatedContainer(
                  key: ValueKey('bottom-nav-${item.route}'),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: itemSize,
                  height: itemSize,
                  decoration: BoxDecoration(
                    color: active ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.oliveDeep)
                                .withValues(alpha: 0.58)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      scale: active ? 1.06 : 0.94,
                      child: AppIcon(
                        item.fallback,
                        asset: item.asset,
                        size: iconSize,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
