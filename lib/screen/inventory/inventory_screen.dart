import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/audio/app_audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/inventory_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/game_back_button.dart';
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_async_state.dart';
import '../../widgets/common/bottom_navigation.dart';
import '../../widgets/common/home_page_backdrop.dart';
import '../../widgets/common/game_notification_dialog.dart';

enum InventoryCategory { food, materials }

class _InventoryDisplayItem {
  const _InventoryDisplayItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.category,
    this.itemTypeName,
    this.image,
    this.description,
    this.effectTypeCode,
    this.effectValue,
  });

  final String itemId;
  final String name;
  final int quantity;
  final InventoryCategory category;
  final String? itemTypeName;
  final String? image;
  final String? description;
  final String? effectTypeCode;
  final int? effectValue;
}

class _InventoryCategoryTab {
  const _InventoryCategoryTab({
    required this.id,
    required this.label,
    required this.icon,
  });

  final InventoryCategory id;
  final String label;
  final IconData icon;
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const int _gridSlotCount = 24;

  final InventoryScreenRepository _repository = InventoryScreenRepository();
  bool _isLoading = true;
  bool _showItemPopup = false;
  String? _errorMessage;
  String? _usingItemId;
  String? _selectedItemId;
  List<_InventoryDisplayItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  InventoryCategory _resolveCategory(String itemTypeName) {
    final type = itemTypeName.toLowerCase();
    if (type.contains('food') ||
        type.contains('tiêu hao') ||
        type.contains('consume') ||
        type.contains('consumable')) {
      return InventoryCategory.food;
    }
    return InventoryCategory.materials;
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiItems = await _repository.getInventory();
      final food = <_InventoryDisplayItem>[];
      final materials = <_InventoryDisplayItem>[];

      for (final item in apiItems) {
        final mapped = _InventoryDisplayItem(
          itemId: item.itemId,
          name: item.itemName,
          quantity: item.quantity,
          category: _resolveCategory(item.itemTypeName),
          itemTypeName: item.itemTypeName,
          image: item.image,
          description: item.description,
          effectTypeCode: item.effectTypeCode,
          effectValue: item.effectValue,
        );

        if (mapped.category == InventoryCategory.food) {
          food.add(mapped);
        } else {
          materials.add(mapped);
        }
      }

      if (!mounted) return;
      setState(() {
        _items = [...food, ...materials];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _errorMessage = AppLocalizations.of(context).inventoryLoadError;
        _isLoading = false;
      });
    }
  }

  List<_InventoryDisplayItem> get _currentItems => _items;

  _InventoryDisplayItem? get _selectedItem {
    final selectedId = _selectedItemId;
    if (selectedId == null) return null;
    for (final item in _items) {
      if (item.itemId == selectedId) return item;
    }
    return null;
  }

  void _handleSelectItem(String itemId) {
    setState(() {
      _selectedItemId = itemId;
      _showItemPopup = true;
    });
  }

  void _closeItemPopup() {
    setState(() => _showItemPopup = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    showGameNotificationDialog(context, message: message, isSuccess: false);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showGameNotificationDialog(context, message: message, isSuccess: true);
  }

  String _formatEffect(_InventoryDisplayItem item) {
    final code = item.effectTypeCode?.trim();
    final value = item.effectValue;
    if (code != null && code.isNotEmpty && value != null) {
      final prefix = value > 0 ? '+' : '';
      return '$prefix$value $code';
    }
    if (code != null && code.isNotEmpty) return code;
    return AppLocalizations.of(context).inventoryNoEffect;
  }

  Color _itemColor(_InventoryDisplayItem item, bool isDark) {
    final effect = (item.effectTypeCode ?? '').toLowerCase();
    if (effect.contains('life') || effect == 'sml') {
      return isDark ? AppColors.darkLife : AppColors.lightLife;
    }
    if (effect.contains('bond')) {
      return isDark ? AppColors.darkBond : AppColors.lightBond;
    }
    if (effect.contains('energy')) {
      return const Color(0xFF6366F1);
    }
    return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  }

  IconData _itemIcon(_InventoryDisplayItem item) {
    final effect = (item.effectTypeCode ?? '').toLowerCase();
    if (effect.contains('life') || effect == 'sml') {
      return Icons.water_drop_outlined;
    }
    if (effect.contains('bond')) {
      return Icons.cake_outlined;
    }
    if (effect.contains('energy')) {
      return Icons.bolt_outlined;
    }
    return Icons.auto_awesome;
  }

  Future<void> _handleUse(_InventoryDisplayItem item) async {
    AppAudioService.instance.suppressNextTabSound();
    setState(() => _usingItemId = item.itemId);
    try {
      final resp = await _repository.useItem(item.itemId);
      if (resp.success) {
        unawaited(AppAudioService.instance.playUseItem());
        if (mounted) {
          _showSuccess(AppLocalizations.of(context).inventoryUsed(item.name));
        }
        if (!mounted) return;
        final gameState = context.read<GameStateProvider>();
        await Future.wait([
          gameState.fetchPetStatus(),
          gameState.fetchPetVisual(),
        ]);
        if (!mounted) return;
        _closeItemPopup();
        await _loadInventory();
      } else if (mounted) {
        _showError(
          AppLocalizations.of(context).inventoryUseFailed(resp.message),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(
          AppLocalizations.of(context).inventoryUseError(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _usingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final primary = theme.colorScheme.primary;
    final selectedItem = _selectedItem;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const BottomNavigation(),
      body: HomePageBackdrop(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _InventoryPanel(
                      title: l10n.inventoryBag,
                      child: _isLoading
                          ? Center(
                              child: GameLoadingIndicator(label: l10n.loading),
                            )
                          : Stack(
                              children: [
                                _ItemGrid(
                                  slotCount: _gridSlotCount,
                                  items: _currentItems,
                                  selectedItemId: _selectedItemId,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                  itemColor: _itemColor,
                                  itemIcon: _itemIcon,
                                  onSelectItem: _handleSelectItem,
                                ),
                                if (_errorMessage != null)
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.authCard.withValues(
                                          alpha: 0.94,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.wood,
                                        ),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.woodDeep,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showItemPopup && selectedItem != null)
              _ItemDetailPopup(
                item: selectedItem,
                cardColor: cardColor,
                borderColor: borderColor,
                foreground: foreground,
                mutedForeground: mutedForeground,
                muted: muted,
                accent: accent,
                primary: primary,
                isDark: isDark,
                isUsing: _usingItemId == selectedItem.itemId,
                statBonus: _formatEffect(selectedItem),
                itemColor: _itemColor(selectedItem, isDark),
                itemIcon: _itemIcon(selectedItem),
                onClose: _closeItemPopup,
                onUse: () => _handleUse(selectedItem),
              ),
          ],
        ),
      ),
    );
  }
}

extension on _InventoryScreenState {
  Widget _buildBottomNavigation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeIconColor = isDark
        ? const Color(0xFF1E2E24)
        : const Color(0xFFFFF8F0);
    final inactiveColor = isDark
        ? AppColors.darkMutedForeground.withValues(alpha: 0.66)
        : AppColors.lightMutedForeground.withValues(alpha: 0.66);

    return Container(
      height: 80,
      decoration: BoxDecoration(color: Colors.transparent),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                iconWidget: AppIcon(
                  Icons.bolt_rounded,
                  asset: AppAssets.iconFriendsNav,
                  size: 22,
                  color: inactiveColor,
                ),
                label: l10n.inventoryCommunity,
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/friends'),
              ),
              _buildNavItem(
                iconWidget: _SwordsIcon(size: 22, color: inactiveColor),
                label: 'PvP',
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/pvp'),
              ),
              const SizedBox(width: 64),
              _buildNavItem(
                iconWidget: AppIcon(
                  Icons.backpack_outlined,
                  size: 22,
                  color: inactiveColor,
                ),
                label: l10n.inventoryBag,
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/inventory'),
              ),
              _buildNavItem(
                iconWidget: AppIcon(
                  Icons.storefront_outlined,
                  size: 22,
                  color: inactiveColor,
                ),
                label: l10n.inventoryStore,
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/shop'),
              ),
            ],
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD89A70),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF895B3D),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD89A70,
                          ).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AppIcon(
                        Icons.home_rounded,
                        size: 36,
                        color: activeIconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Widget iconWidget,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD89A70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF895B3D), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Transform.scale(scale: 1.65, child: iconWidget),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwordsIcon extends StatelessWidget {
  const _SwordsIcon({this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SwordsPainter(color: color ?? Colors.white),
    );
  }
}

class _SwordsPainter extends CustomPainter {
  const _SwordsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w * 0.25, h * 0.75),
      Offset(w * 0.75, h * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.2, h * 0.55),
      Offset(w * 0.45, h * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.75, h * 0.75),
      Offset(w * 0.25, h * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.8, h * 0.55),
      Offset(w * 0.55, h * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SwordsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.foreground,
    required this.cardColor,
    required this.borderColor,
    required this.mutedForeground,
    required this.onBack,
  });

  final Color foreground;
  final Color cardColor;
  final Color borderColor;
  final Color mutedForeground;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Keep the callback/class shape stable for hot reload, but root screens
        // reachable from BottomNavigation must not expose a back action.
        Offstage(
          child: GameBackButton(
            semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
          ),
        ),
        GameButtonLabel(
          AppLocalizations.of(context).inventoryBag,
          fontSize: 20,
          color: AppColors.woodDeep,
          outlineColor: AppColors.authCard,
          outlineWidth: 4,
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.activeCategory,
    required this.cardColor,
    required this.borderColor,
    required this.primary,
    required this.mutedForeground,
    required this.onCategoryChanged,
  });

  final List<_InventoryCategoryTab> categories;
  final InventoryCategory activeCategory;
  final Color cardColor;
  final Color borderColor;
  final Color primary;
  final Color mutedForeground;
  final ValueChanged<InventoryCategory> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: categories.map((cat) {
          final isActive = activeCategory == cat.id;
          return Expanded(
            child: Material(
              color: isActive ? cardColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onCategoryChanged(cat.id),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isActive ? Border.all(color: borderColor) : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        cat.icon,
                        size: 16,
                        color: isActive ? primary : mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive ? primary : mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 20,
          bottom: 4,
          child: Container(
            decoration: BoxDecoration(
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkMuted
                          : AppColors.leafLight)
                      .withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.oliveDeep, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDeep.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          top: 26,
          left: 6,
          right: 6,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 42, 14, 14),
            decoration: BoxDecoration(
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : AppColors.authCard)
                      .withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.wood, width: 1.5),
            ),
            child: child,
          ),
        ),
        Positioned(
          top: 0,
          left: 46,
          right: 46,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(minWidth: 150),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.woodLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.woodDeep, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.woodDeep.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GameButtonLabel(title, fontSize: 18, outlineWidth: 3),
            ),
          ),
        ),
        const Positioned(
          left: -5,
          top: 16,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(68, 68),
              painter: _FloralCornerPainter(),
            ),
          ),
        ),
        Positioned(
          right: -7,
          bottom: -2,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: 3.14159,
              child: const CustomPaint(
                size: Size(78, 78),
                painter: _FloralCornerPainter(showFlower: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloralCornerPainter extends CustomPainter {
  const _FloralCornerPainter({this.showFlower = false});

  final bool showFlower;

  @override
  void paint(Canvas canvas, Size size) {
    final stem = Paint()
      ..color = AppColors.oliveDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.fill;
    final leafEdge = Paint()
      ..color = AppColors.oliveDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..moveTo(5, size.height - 5)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.62,
        size.width - 7,
        7,
      );
    canvas.drawPath(path, stem);

    void drawLeaf(Offset center, double angle, double width, double height) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: height,
      );
      canvas.drawOval(rect, leaf);
      canvas.drawOval(rect, leafEdge);
      canvas.restore();
    }

    drawLeaf(Offset(size.width * 0.28, size.height * 0.68), -0.65, 21, 11);
    drawLeaf(Offset(size.width * 0.43, size.height * 0.53), 0.75, 22, 11);
    drawLeaf(Offset(size.width * 0.6, size.height * 0.35), -0.62, 20, 10);

    if (showFlower) {
      final flowerCenter = Offset(size.width * 0.7, size.height * 0.24);
      final petal = Paint()
        ..color = AppColors.blossom
        ..style = PaintingStyle.fill;
      final petalEdge = Paint()
        ..color = AppColors.wood
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      for (var i = 0; i < 5; i++) {
        final angle = i * 1.25664;
        final center = flowerCenter + Offset.fromDirection(angle, 9);
        canvas.drawCircle(center, 6.5, petal);
        canvas.drawCircle(center, 6.5, petalEdge);
      }
      canvas.drawCircle(flowerCenter, 5, Paint()..color = AppColors.goldLight);
      canvas.drawCircle(flowerCenter, 5, petalEdge);
    }
  }

  @override
  bool shouldRepaint(covariant _FloralCornerPainter oldDelegate) =>
      oldDelegate.showFlower != showFlower;
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.slotCount,
    required this.items,
    required this.selectedItemId,
    required this.borderColor,
    required this.isDark,
    required this.itemColor,
    required this.itemIcon,
    required this.onSelectItem,
  });

  final int slotCount;
  final List<_InventoryDisplayItem> items;
  final String? selectedItemId;
  final Color borderColor;
  final bool isDark;
  final Color Function(_InventoryDisplayItem item, bool isDark) itemColor;
  final IconData Function(_InventoryDisplayItem item) itemIcon;
  final ValueChanged<String> onSelectItem;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 310 ? 5 : 4;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 72),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: slotCount,
          itemBuilder: (context, index) {
            if (index < items.length) {
              final item = items[index];
              return _AnimatedItemSlot(
                index: index,
                item: item,
                isSelected: selectedItemId == item.itemId,
                color: itemColor(item, isDark),
                icon: itemIcon(item),
                isDark: isDark,
                onTap: () => onSelectItem(item.itemId),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkMuted.withValues(alpha: 0.74)
                    : AppColors.panelMuted.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.48),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.woodDeep.withValues(alpha: 0.07),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedItemSlot extends StatefulWidget {
  const _AnimatedItemSlot({
    required this.index,
    required this.item,
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final int index;
  final _InventoryDisplayItem item;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_AnimatedItemSlot> createState() => _AnimatedItemSlotState();
}

class _AnimatedItemSlotState extends State<_AnimatedItemSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future<void>.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.item.image?.trim();
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: widget.isDark
              ? AppColors.darkMuted
              : AppColors.panelMuted.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          elevation: widget.isSelected ? 3 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.oliveDeep
                      : AppColors.wood.withValues(alpha: 0.58),
                  width: widget.isSelected ? 2.6 : 1.4,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasImage)
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagePath!.startsWith('assets/')
                            ? Image.asset(
                                imagePath,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => AppIcon(
                                  widget.icon,
                                  size: 32,
                                  color: widget.color,
                                ),
                              )
                            : Image.network(
                                imagePath,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => AppIcon(
                                  widget.icon,
                                  size: 32,
                                  color: widget.color,
                                ),
                              ),
                      ),
                    )
                  else
                    AppIcon(
                      widget.icon,
                      size: 32,
                      color: widget.color,
                      shadows: const [
                        Shadow(color: Color(0x33000000), blurRadius: 2),
                      ],
                    ),
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCard
                                    : AppColors.authCard)
                                .withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: AppColors.wood.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        'x${widget.item.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.woodDeep,
                        ),
                      ),
                    ),
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

class _ItemDetailPopup extends StatelessWidget {
  const _ItemDetailPopup({
    required this.item,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    required this.muted,
    required this.accent,
    required this.primary,
    required this.isDark,
    required this.isUsing,
    required this.statBonus,
    required this.itemColor,
    required this.itemIcon,
    required this.onClose,
    required this.onUse,
  });

  final _InventoryDisplayItem item;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color muted;
  final Color accent;
  final Color primary;
  final bool isDark;
  final bool isUsing;
  final String statBonus;
  final Color itemColor;
  final IconData itemIcon;
  final VoidCallback onClose;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final imagePath = item.image?.trim();
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 108),
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {},
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value * 80),
                      child: Opacity(
                        opacity: (1 - (value * 0.3)).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                    decoration: BoxDecoration(
                      color: isDark ? cardColor : AppColors.authCard,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? borderColor : AppColors.wood,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: onClose,
                            constraints: const BoxConstraints.tightFor(
                              width: 40,
                              height: 40,
                            ),
                            padding: EdgeInsets.zero,
                            icon: AppIcon(
                              Icons.close,
                              size: 28,
                              color: mutedForeground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: itemColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.wood.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? imagePath!.startsWith('assets/')
                                    ? Image.asset(
                                        imagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => AppIcon(
                                          itemIcon,
                                          size: 48,
                                          color: itemColor,
                                        ),
                                      )
                                    : Image.network(
                                        imagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => AppIcon(
                                          itemIcon,
                                          size: 48,
                                          color: itemColor,
                                        ),
                                      )
                              : AppIcon(itemIcon, size: 48, color: itemColor),
                        ),
                        const SizedBox(height: 18),
                        GameButtonLabel(
                          item.name,
                          fontSize: 23,
                          color: isDark ? foreground : AppColors.woodDeep,
                          outlineColor: isDark
                              ? AppColors.darkCard
                              : AppColors.creamLight,
                          outlineWidth: 3,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? primary.withValues(alpha: 0.18)
                                : AppColors.leafLight.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark
                                  ? primary.withValues(alpha: 0.35)
                                  : AppColors.wood.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            statBonus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? primary : AppColors.woodDeep,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          item.description?.trim().isNotEmpty == true
                              ? item.description!.trim()
                              : l10n.inventoryNoDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? mutedForeground
                                : AppColors.inkBrown,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: _PopupButton(
                                label: l10n.close,
                                backgroundColor: isDark
                                    ? muted
                                    : AppColors.buttonSecondary,
                                foregroundColor: AppColors.woodDeep,
                                onPressed: onClose,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PopupButton(
                                label: isUsing
                                    ? l10n.processing
                                    : l10n.inventoryUse,
                                backgroundColor: isDark
                                    ? accent
                                    : AppColors.buttonYellow,
                                foregroundColor: isDark
                                    ? AppColors.darkPrimaryForeground
                                    : AppColors.buttonText,
                                onPressed: isUsing ? null : onUse,
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
          ),
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  const _PopupButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 0,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.woodDeep, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: GameButtonLabel(
            label,
            fontSize: 14,
            color: foregroundColor,
            outlineColor: foregroundColor == AppColors.buttonText
                ? AppColors.woodDeep
                : AppColors.authCard,
            outlineWidth: 2.2,
          ),
        ),
      ),
    );
  }
}
