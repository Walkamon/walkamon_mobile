import 'dart:ui';
import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  bool _isTabActive(String itemRoute, String? currentRoute) {
    if (currentRoute == null) return false;

    if (itemRoute == '/social' &&
        (currentRoute == '/social' ||
            currentRoute == '/friends' ||
            currentRoute == '/home/quests')) {
      return true;
    }

    if (itemRoute == '/home' && currentRoute == '/home') return true;
    if (itemRoute == '/shop' &&
        (currentRoute == '/shop' || currentRoute == '/home/shop'))
      return true;
    if (itemRoute == '/inventory' &&
        (currentRoute == '/inventory' || currentRoute == '/home/inventory'))
      return true;
    if (itemRoute == '/profile' &&
        (currentRoute == '/profile' || currentRoute == '/home/profile'))
      return true;

    return currentRoute == itemRoute;
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final colorScheme = Theme.of(context).colorScheme;

    final navItems = [
      {'to': '/home', 'icon': Icons.home_rounded, 'label': 'Home'},
      {'to': '/shop', 'icon': Icons.storefront_rounded, 'label': 'Shop'},
      {'to': '/inventory', 'icon': Icons.backpack_rounded, 'label': 'Bag'},
      {'to': '/social', 'icon': Icons.track_changes_rounded, 'label': 'Quest'},
      {'to': '/profile', 'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        height:
            72, // Đặt cố định chiều cao để không bao giờ bị giãn tràn màn hình
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: navItems.map((item) {
                  final route = item['to'] as String;
                  final label = item['label'] as String;
                  final icon = item['icon'] as IconData;

                  final isActive = _isTabActive(route, currentRoute);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isActive) {
                          Navigator.pushReplacementNamed(context, route);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: 54,
                          height: 54, // Chiều cao ôm vừa icon và text
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize
                                .min, // Cực kỳ quan trọng để không bị giãn
                            children: [
                              AnimatedScale(
                                scale: isActive ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  icon,
                                  size: 22,
                                  color: isActive
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isActive
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                              ),
                            ],
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
