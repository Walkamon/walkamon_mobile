import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

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
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.darkNavigationIcon
        : AppColors.lightNavigationIcon;
    final itemColor = isDark
        ? AppColors.darkNavigation
        : AppColors.lightNavigation;
    final activeColor = isDark
        ? AppColors.darkNavigationActive
        : AppColors.lightNavigationActive;
    final borderColor = isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

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

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: SizedBox(
        height: 66,
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
                  duration: const Duration(milliseconds: 180),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: active ? activeColor : itemColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AppIcon(
                      item.fallback,
                      asset: item.asset,
                      size: 36,
                      color: iconColor,
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
