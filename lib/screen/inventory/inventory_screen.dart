import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/inventory_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/error_message_widget.dart';
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
    setState(() => _usingItemId = item.itemId);
    try {
      final resp = await _repository.useItem(item.itemId);
      if (resp.success) {
        if (mounted) {
          _showSuccess(AppLocalizations.of(context).inventoryUsed(item.name));
        }
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
    final hasAnyItem = _items.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigation(context),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InventoryHeader(
                  foreground: foreground,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  mutedForeground: mutedForeground,
                  onBack: () => Navigator.pushNamed(context, '/home'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : !hasAnyItem
                      ? Center(
                          child: Text(
                            _errorMessage ?? l10n.inventoryNoItems,
                            style: TextStyle(color: mutedForeground),
                          ),
                        )
                      : _ItemGrid(
                          slotCount: _gridSlotCount,
                          items: _currentItems,
                          selectedItemId: _selectedItemId,
                          borderColor: borderColor,
                          isDark: isDark,
                          itemColor: _itemColor,
                          itemIcon: _itemIcon,
                          onSelectItem: _handleSelectItem,
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
    );
  }
}

extension on _InventoryScreenState {
  Widget _buildBottomNavigation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBgColor = isDark
        ? const Color(0xFF25332A)
        : const Color(0xFFE5DCCF);
    final activeBgColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final activeIconColor = isDark
        ? const Color(0xFF1E2E24)
        : const Color(0xFFFFF8F0);
    final inactiveColor = isDark
        ? AppColors.darkMutedForeground.withValues(alpha: 0.66)
        : AppColors.lightMutedForeground.withValues(alpha: 0.66);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
            top: -18,
            child: GestureDetector(
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeBgColor,
                      boxShadow: [
                        BoxShadow(
                          color: activeBgColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AppIcon(
                        Icons.home_rounded,
                        size: 28,
                        color: activeIconColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.inventoryHome,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.lightForeground,
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              color: cardColor,
              shape: CircleBorder(side: BorderSide(color: borderColor)),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: AppIcon(
                    Icons.arrow_back,
                    size: 20,
                    color: mutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        Text(
          AppLocalizations.of(context).inventoryBag,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
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
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor.withValues(alpha: 0.4)),
          ),
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
    final hasImage = widget.item.image != null && widget.item.image!.isNotEmpty;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: widget.color,
          borderRadius: BorderRadius.circular(24),
          elevation: widget.isSelected ? 4 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isSelected
                      ? (widget.isDark
                            ? AppColors.darkBackground
                            : Colors.white)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        widget.item.image!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            AppIcon(widget.icon, size: 36, color: Colors.white),
                      ),
                    )
                  else
                    AppIcon(
                      widget.icon,
                      size: 36,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x33000000), blurRadius: 2),
                      ],
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x${widget.item.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
    final hasImage = item.image != null && item.image!.isNotEmpty;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value * 80),
                      child: Opacity(opacity: 1 - (value * 0.3), child: child),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 384),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Material(
                            color: muted,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: onClose,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: AppIcon(
                                  Icons.close,
                                  size: 18,
                                  color: mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: itemColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? Image.network(
                                  item.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => AppIcon(
                                    itemIcon,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                )
                              : AppIcon(
                                  itemIcon,
                                  size: 40,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            statBonus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? primary : foreground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description?.trim().isNotEmpty == true
                              ? item.description!.trim()
                              : l10n.inventoryNoDescription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: mutedForeground,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _PopupButton(
                                label: l10n.close,
                                backgroundColor: muted,
                                foregroundColor: foreground,
                                onPressed: onClose,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PopupButton(
                                label: isUsing
                                    ? l10n.processing
                                    : l10n.inventoryUse,
                                backgroundColor: accent,
                                foregroundColor: isDark
                                    ? AppColors.darkPrimaryForeground
                                    : AppColors.lightPrimaryForeground,
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
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
