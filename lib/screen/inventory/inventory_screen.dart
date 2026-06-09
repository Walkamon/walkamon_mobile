import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum InventoryCategory { food, materials }

class _InventorySlotItem {
  const _InventorySlotItem({
    required this.id,
    required this.name,
    required this.count,
    required this.description,
    required this.statBonus,
    required this.color,
    required this.icon,
    required this.actionLabel,
  });

  final int id;
  final String name;
  final int count;
  final String description;
  final String statBonus;
  final Color color;
  final IconData icon;
  final String actionLabel;
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

  InventoryCategory _activeCategory = InventoryCategory.food;
  final Map<InventoryCategory, int?> _selectedItemIds = {
    InventoryCategory.food: null,
    InventoryCategory.materials: null,
  };
  bool _showItemPopup = false;

  late final Map<InventoryCategory, List<_InventorySlotItem>> _itemsData;

  @override
  void initState() {
    super.initState();
    _itemsData = _buildMockItems();
  }

  Map<InventoryCategory, List<_InventorySlotItem>> _buildMockItems() {
    return {
      InventoryCategory.food: const [
        _InventorySlotItem(
          id: 2,
          name: 'Bình Hồi Năng Lượng',
          count: 5,
          description:
              'Nước uống đặc biệt giúp Lumina phục hồi Sinh Mệnh Lực ngay lập tức.',
          statBonus: '+50% Sinh Mệnh Lực',
          color: AppColors.lightLife,
          icon: Icons.water_drop_outlined,
          actionLabel: 'Sử Dụng',
        ),
        _InventorySlotItem(
          id: 3,
          name: 'Bình Hồi Gắn Kết',
          count: 2,
          description:
              'Bình uống ngọt ngào giúp tăng cường Độ Gắn Kết với Lumina.',
          statBonus: '+30% Độ Gắn Kết',
          color: AppColors.lightBond,
          icon: Icons.cake_outlined,
          actionLabel: 'Sử Dụng',
        ),
      ],
      InventoryCategory.materials: const [
        _InventorySlotItem(
          id: 4,
          name: 'Thẻ Đổi Tên',
          count: 1,
          description:
              'Vật phẩm đặc biệt cho phép bạn thay đổi tên của Tinh Linh đồng hành.',
          statBonus: 'Đổi tên vật nuôi',
          color: AppColors.lightPrimary,
          icon: Icons.auto_awesome,
          actionLabel: 'Sử Dụng',
        ),
        _InventorySlotItem(
          id: 5,
          name: 'Thẻ Giảm Cooldown',
          count: 3,
          description:
              'Giảm ngay 2 giờ thời gian chờ (cooldown) cho các hoạt động của Tinh Linh.',
          statBonus: '-2 Giờ Chờ',
          color: Color(0xFF6366F1),
          icon: Icons.star_outline,
          actionLabel: 'Sử Dụng',
        ),
      ],
    };
  }

  List<_InventoryCategoryTab> _categories(bool isDark) {
    return [
      _InventoryCategoryTab(
        id: InventoryCategory.food,
        label: 'Tiêu hao',
        icon: Icons.inventory_2_outlined,
      ),
      _InventoryCategoryTab(
        id: InventoryCategory.materials,
        label: 'Nguyên liệu',
        icon: Icons.auto_awesome,
      ),
    ];
  }

  void _handleCategoryChange(InventoryCategory category) {
    setState(() => _activeCategory = category);
  }

  void _handleSelectItem(int id) {
    setState(() {
      _selectedItemIds[_activeCategory] = id;
      _showItemPopup = true;
    });
  }

  void _closeItemPopup() {
    setState(() => _showItemPopup = false);
  }

  _InventorySlotItem? get _selectedItem {
    final selectedId = _selectedItemIds[_activeCategory];
    if (selectedId == null) return null;

    final items = _itemsData[_activeCategory] ?? [];
    for (final item in items) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  List<_InventorySlotItem> get _currentItems =>
      _itemsData[_activeCategory] ?? [];

  int? get _selectedItemId => _selectedItemIds[_activeCategory];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final selectedItem = _selectedItem;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                const SizedBox(height: 24),
                _CategoryTabs(
                  categories: _categories(isDark),
                  activeCategory: _activeCategory,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primary: primary,
                  mutedForeground: mutedForeground,
                  foreground: foreground,
                  onCategoryChanged: _handleCategoryChange,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _ItemGrid(
                    slotCount: _gridSlotCount,
                    items: _currentItems,
                    selectedItemId: _selectedItemId,
                    borderColor: borderColor,
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
              onClose: _closeItemPopup,
            ),
        ],
      ),
    );
  }
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
              shape: CircleBorder(
                side: BorderSide(color: borderColor),
              ),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.05),
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
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
          'Túi Đồ',
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
    required this.foreground,
    required this.onCategoryChanged,
  });

  final List<_InventoryCategoryTab> categories;
  final InventoryCategory activeCategory;
  final Color cardColor;
  final Color borderColor;
  final Color primary;
  final Color mutedForeground;
  final Color foreground;
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
                    border: isActive
                        ? Border.all(color: borderColor)
                        : null,
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
                      Icon(
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
    required this.onSelectItem,
  });

  final int slotCount;
  final List<_InventorySlotItem> items;
  final int? selectedItemId;
  final Color borderColor;
  final ValueChanged<int> onSelectItem;

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
            isSelected: selectedItemId == item.id,
            onTap: () => onSelectItem(item.id),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.05,
            ),
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
    required this.onTap,
  });

  final int index;
  final _InventorySlotItem item;
  final bool isSelected;
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
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: widget.item.color,
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
                      ? (isDark
                            ? AppColors.darkBackground
                            : Colors.white)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    widget.item.icon,
                    size: 36,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 2,
                      ),
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
                        'x${widget.item.count}',
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
    required this.onClose,
  });

  final _InventorySlotItem item;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color muted;
  final Color accent;
  final Color primary;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
                      child: Opacity(
                        opacity: 1 - (value * 0.3),
                        child: child,
                      ),
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
                                child: Icon(
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
                            color: item.color,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            item.icon,
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
                            item.statBonus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? primary : foreground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
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
                                label: 'Đóng',
                                backgroundColor: muted,
                                foregroundColor: foreground,
                                onPressed: onClose,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PopupButton(
                                label: item.actionLabel,
                                backgroundColor: accent,
                                foregroundColor: isDark
                                    ? AppColors.darkPrimaryForeground
                                    : AppColors.lightPrimaryForeground,
                                onPressed: onClose,
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
  final VoidCallback onPressed;

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
