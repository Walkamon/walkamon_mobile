import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/shop_item_response.dart';
import '../../data/repositories/shop_screen_repository.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/dewdrop_icon.dart';
import '../../widgets/layouts/root_layout.dart';

enum ShopCategory { food, materials }

class _ShopDisplayItem {
  const _ShopDisplayItem({
    required this.shopItemId,
    required this.name,
    required this.description,
    required this.statBonus,
    required this.price,
    required this.limit,
    required this.color,
    required this.icon,
    required this.category,
  });

  final String shopItemId;
  final String name;
  final String description;
  final String statBonus;
  final int price;
  final int limit;
  final Color color;
  final IconData icon;
  final ShopCategory category;
}

class _ShopCategoryTab {
  const _ShopCategoryTab({
    required this.id,
    required this.label,
    required this.icon,
  });

  final ShopCategory id;
  final String label;
  final IconData icon;
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ShopScreenRepository _repository = ShopScreenRepository();

  ShopCategory _activeCategory = ShopCategory.food;
  final Map<ShopCategory, String?> _selectedItemIds = {
    ShopCategory.food: null,
    ShopCategory.materials: null,
  };

  bool _showItemPopup = false;
  bool _isLoading = true;
  bool _isLoadingDetail = false;
  bool _isBuying = false;
  String? _errorMessage;

  List<_ShopDisplayItem> _allItems = [];
  _ShopDisplayItem? _detailItem;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
  }

  Future<void> _loadShopItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiItems = await _repository.getAllShopItems();
      final items = _mapApiItems(apiItems);

      if (!mounted) return;
      setState(() {
        _allItems = items.isNotEmpty ? items : _buildMockItems();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allItems = _buildMockItems();
        _isLoading = false;
      });
    }
  }

  List<_ShopDisplayItem> _mapApiItems(List<ShopItemResponse> apiItems) {
    return apiItems.map((item) {
      final meta = _uiMetaForItemName(item.itemName);
      return _ShopDisplayItem(
        shopItemId: item.shopItemId,
        name: item.itemName,
        description: meta.description,
        statBonus: meta.statBonus,
        price: item.priceAmount,
        limit: meta.limit,
        color: meta.color,
        icon: meta.icon,
        category: meta.category,
      );
    }).toList();
  }

  List<_ShopDisplayItem> _buildMockItems() {
    return [
      const _ShopDisplayItem(
        shopItemId: 'mock-food-2',
        name: 'Bình Hồi Năng Lượng',
        description: 'Hồi phục ngay lập tức',
        statBonus: '+50% Sinh Mệnh Lực',
        price: 100,
        limit: 5,
        color: AppColors.lightLife,
        icon: Icons.water_drop_outlined,
        category: ShopCategory.food,
      ),
      const _ShopDisplayItem(
        shopItemId: 'mock-food-3',
        name: 'Bình Hồi Gắn Kết',
        description: 'Tăng điểm thân thiết',
        statBonus: '+30% Độ Gắn Kết',
        price: 150,
        limit: 3,
        color: AppColors.lightBond,
        icon: Icons.cake_outlined,
        category: ShopCategory.food,
      ),
      const _ShopDisplayItem(
        shopItemId: 'mock-material-4',
        name: 'Thẻ Đổi Tên',
        description: 'Sử dụng 1 lần',
        statBonus: 'Đổi tên Tinh Linh',
        price: 500,
        limit: 1,
        color: AppColors.lightAccent,
        icon: Icons.auto_awesome,
        category: ShopCategory.materials,
      ),
      const _ShopDisplayItem(
        shopItemId: 'mock-material-5',
        name: 'Thẻ Giảm Cooldown',
        description: 'Bỏ qua thời gian chờ',
        statBonus: '-2 Giờ Chờ',
        price: 300,
        limit: 10,
        color: AppColors.lightPrimary,
        icon: Icons.star_outline,
        category: ShopCategory.materials,
      ),
    ];
  }

  _ShopItemUiMeta _uiMetaForItemName(String name) {
    const known = {
      'Bình Hồi Năng Lượng': _ShopItemUiMeta(
        description: 'Hồi phục ngay lập tức',
        statBonus: '+50% Sinh Mệnh Lực',
        limit: 5,
        color: AppColors.lightLife,
        icon: Icons.water_drop_outlined,
        category: ShopCategory.food,
      ),
      'Bình Hồi Gắn Kết': _ShopItemUiMeta(
        description: 'Tăng điểm thân thiết',
        statBonus: '+30% Độ Gắn Kết',
        limit: 3,
        color: AppColors.lightBond,
        icon: Icons.cake_outlined,
        category: ShopCategory.food,
      ),
      'Thẻ Đổi Tên': _ShopItemUiMeta(
        description: 'Sử dụng 1 lần',
        statBonus: 'Đổi tên Tinh Linh',
        limit: 1,
        color: AppColors.lightAccent,
        icon: Icons.auto_awesome,
        category: ShopCategory.materials,
      ),
      'Thẻ Giảm Cooldown': _ShopItemUiMeta(
        description: 'Bỏ qua thời gian chờ',
        statBonus: '-2 Giờ Chờ',
        limit: 10,
        color: AppColors.lightPrimary,
        icon: Icons.star_outline,
        category: ShopCategory.materials,
      ),
    };

    return known[name] ??
        const _ShopItemUiMeta(
          description: 'Vật phẩm cửa hàng',
          statBonus: 'Hiệu ứng đặc biệt',
          limit: 1,
          color: AppColors.lightPrimary,
          icon: Icons.inventory_2_outlined,
          category: ShopCategory.food,
        );
  }

  List<_ShopDisplayItem> get _currentItems =>
      _allItems.where((item) => item.category == _activeCategory).toList();

  _ShopDisplayItem? get _selectedItem {
    final selectedId = _selectedItemIds[_activeCategory];
    if (selectedId == null) return null;

    for (final item in _currentItems) {
      if (item.shopItemId == selectedId) return item;
    }
    return null;
  }

  Future<void> _handleSelectItem(String shopItemId) async {
    setState(() {
      _selectedItemIds[_activeCategory] = shopItemId;
      _showItemPopup = true;
      _detailItem = _selectedItem;
      _isLoadingDetail = true;
    });

    try {
      final detail = await _repository.getShopItemById(shopItemId);
      if (!mounted) return;

      final meta = _uiMetaForItemName(detail.itemName);
      setState(() {
        _detailItem = _ShopDisplayItem(
          shopItemId: detail.shopItemId,
          name: detail.itemName,
          description: meta.description,
          statBonus: meta.statBonus,
          price: detail.priceAmount,
          limit: meta.limit,
          color: meta.color,
          icon: meta.icon,
          category: meta.category,
        );
        _isLoadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _handleBuy(_ShopDisplayItem item) async {
    if (_isBuying) return;

    final gameState = context.read<GameStateProvider>();

    if (gameState.user == null) {
      RootLayout.showToast('Vui lòng đăng nhập để mua vật phẩm.');
      return;
    }

    if (!gameState.canAfford(item.price)) {
      RootLayout.showToast('Không đủ Giọt Sương để mua vật phẩm này.');
      return;
    }

    setState(() => _isBuying = true);

    final apiSuccess = await _repository.buyShopItem(item.shopItemId);
    final purchased =
        apiSuccess || await gameState.buyShopItem(price: item.price);

    if (!mounted) return;

    setState(() {
      _isBuying = false;
      if (purchased) _showItemPopup = false;
    });

    if (purchased) {
      RootLayout.showToast('Đã mua ${item.name} thành công!');
    } else {
      RootLayout.showToast('Mua vật phẩm thất bại. Vui lòng thử lại.');
    }
  }

  void _closeItemPopup() {
    setState(() {
      _showItemPopup = false;
      _detailItem = null;
      _isLoadingDetail = false;
    });
  }

  String _formatCoins(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  List<_ShopCategoryTab> _categories() {
    return const [
      _ShopCategoryTab(
        id: ShopCategory.food,
        label: 'Tiêu hao',
        icon: Icons.inventory_2_outlined,
      ),
      _ShopCategoryTab(
        id: ShopCategory.materials,
        label: 'Nguyên liệu',
        icon: Icons.auto_awesome,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final dewColor = isDark ? AppColors.darkDew : AppColors.lightDew;
    final coins = context.watch<GameStateProvider>().coins;
    final popupItem = _detailItem ?? _selectedItem;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ShopHeader(
                  foreground: foreground,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  mutedForeground: mutedForeground,
                  onBack: () => Navigator.pushNamed(context, '/home'),
                ),
                const SizedBox(height: 24),
                _DewBalanceCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  foreground: foreground,
                  dewColor: dewColor,
                  coins: _formatCoins(coins),
                ),
                const SizedBox(height: 24),
                _CategoryTabs(
                  categories: _categories(),
                  activeCategory: _activeCategory,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primary: primary,
                  mutedForeground: mutedForeground,
                  muted: muted,
                  onCategoryChanged: (category) {
                    setState(() => _activeCategory = category);
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentItems.isEmpty
                      ? Center(
                          child: Text(
                            _errorMessage ?? 'Chưa có vật phẩm trong danh mục này.',
                            style: TextStyle(
                              color: mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _currentItems.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = _currentItems[index];
                            return _ShopItemCard(
                              item: item,
                              index: index,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              foreground: foreground,
                              mutedForeground: mutedForeground,
                              muted: muted,
                              dewColor: dewColor,
                              onTap: () => _handleSelectItem(item.shopItemId),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_showItemPopup && popupItem != null)
            _ShopItemDetailPopup(
              item: popupItem,
              isLoading: _isLoadingDetail,
              isBuying: _isBuying,
              cardColor: cardColor,
              borderColor: borderColor,
              foreground: foreground,
              mutedForeground: mutedForeground,
              muted: muted,
              accent: accent,
              primary: primary,
              dewColor: dewColor,
              isDark: isDark,
              onClose: _closeItemPopup,
              onBuy: () => _handleBuy(popupItem),
            ),
        ],
      ),
    );
  }
}

class _ShopItemUiMeta {
  const _ShopItemUiMeta({
    required this.description,
    required this.statBonus,
    required this.limit,
    required this.color,
    required this.icon,
    required this.category,
  });

  final String description;
  final String statBonus;
  final int limit;
  final Color color;
  final IconData icon;
  final ShopCategory category;
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
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
          'Cửa Hàng',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _DewBalanceCard extends StatelessWidget {
  const _DewBalanceCard({
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.dewColor,
    required this.coins,
  });

  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color dewColor;
  final String coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Giọt Sương',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                DewdropIcon(size: 16, color: dewColor),
                const SizedBox(width: 6),
                Text(
                  coins,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: dewColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    required this.muted,
    required this.onCategoryChanged,
  });

  final List<_ShopCategoryTab> categories;
  final ShopCategory activeCategory;
  final Color cardColor;
  final Color borderColor;
  final Color primary;
  final Color mutedForeground;
  final Color muted;
  final ValueChanged<ShopCategory> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: categories.map((cat) {
          final isActive = activeCategory == cat.id;
          return Expanded(
            child: Material(
              color: isActive ? cardColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onCategoryChanged(cat.id),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                        size: 18,
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

class _ShopItemCard extends StatefulWidget {
  const _ShopItemCard({
    required this.item,
    required this.index,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    required this.muted,
    required this.dewColor,
    required this.onTap,
  });

  final _ShopDisplayItem item;
  final int index;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color muted;
  final Color dewColor;
  final VoidCallback onTap;

  @override
  State<_ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<_ShopItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(-0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Future<void>.delayed(Duration(milliseconds: widget.index * 50), () {
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(20),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: widget.item.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: widget.foreground,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.item.description,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    color: widget.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 80,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${widget.item.price}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.foreground,
                              ),
                            ),
                            const SizedBox(width: 4),
                            DewdropIcon(size: 16, color: widget.dewColor),
                          ],
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

class _ShopItemDetailPopup extends StatelessWidget {
  const _ShopItemDetailPopup({
    required this.item,
    required this.isLoading,
    required this.isBuying,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    required this.muted,
    required this.accent,
    required this.primary,
    required this.dewColor,
    required this.isDark,
    required this.onClose,
    required this.onBuy,
  });

  final _ShopDisplayItem item;
  final bool isLoading;
  final bool isBuying;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color muted;
  final Color accent;
  final Color primary;
  final Color dewColor;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
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
                    child: isLoading
                        ? SizedBox(
                            height: 220,
                            child: Center(
                              child: CircularProgressIndicator(color: primary),
                            ),
                          )
                        : Column(
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
                                      label: isBuying ? 'Đang mua...' : '${item.price}',
                                      backgroundColor: accent,
                                      foregroundColor: isDark
                                          ? AppColors.darkPrimaryForeground
                                          : AppColors.lightPrimaryForeground,
                                      onPressed: isBuying ? null : onBuy,
                                      trailing: isBuying
                                          ? null
                                          : DewdropIcon(
                                              size: 16,
                                              color: dewColor,
                                            ),
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
    this.trailing,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final Widget? trailing;

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
