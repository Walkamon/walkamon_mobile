import 'dart:ui';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark
        ? AppColors.darkNavigationIcon
        : AppColors.lightNavigationIcon;
    final activeColor = isDark
        ? AppColors.darkNavigationActive
        : AppColors.lightNavigationActive;
    final barColor = isDark
        ? AppColors.olive.withValues(alpha: 0.9)
        : AppColors.leafLight.withValues(alpha: 0.9);
    final barInnerColor = isDark
        ? AppColors.leafShadow.withValues(alpha: 0.72)
        : AppColors.leafBright.withValues(alpha: 0.52);

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
    final itemSize = (availableWidth / items.length).clamp(44.0, 60.0);
    final iconSize = (itemSize * 0.69).clamp(30.0, 44.0);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.woodDeep, width: 2.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.woodDeep.withValues(alpha: 0.28),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: barInnerColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.oliveDeep.withValues(alpha: 0.72),
                  width: 1.2,
                ),
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
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: itemSize,
                        height: itemSize,
                        decoration: BoxDecoration(
                          color: active ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active
                                ? AppColors.woodDeep
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.woodDeep.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: AppIcon(
                            item.fallback,
                            asset: item.asset,
                            size: iconSize,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
