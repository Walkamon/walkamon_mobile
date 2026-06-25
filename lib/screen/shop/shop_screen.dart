import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/shop_screen_repository.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/error_message_widget.dart';

class _ShopDisplayItem {
  const _ShopDisplayItem({
    required this.shopItemId,
    required this.name,
    required this.price,
    required this.isActive,
    this.image,
    this.itemTypeName,
    this.description,
  });

  final String shopItemId;
  final String name;
  final int price;
  final bool isActive;
  final String? image;
  final String? itemTypeName;
  final String? description;
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ShopScreenRepository _repository = ShopScreenRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<_ShopDisplayItem> _items = [];
  _ShopDisplayItem? _selectedItem;
  String? _buyingItemId;

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
      final items = apiItems
          .map(
            (item) => _ShopDisplayItem(
              shopItemId: item.shopItemId,
              name: item.itemName,
              price: item.priceAmount,
              isActive: item.isActive,
              image: item.image,
              itemTypeName: item.itemTypeName,
              description: item.description,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _errorMessage = 'Không tải được dữ liệu shop.';
        _isLoading = false;
      });
    }
  }

  void _openDetail(_ShopDisplayItem item) {
    setState(() => _selectedItem = item);
  }

  void _closeDetail() {
    setState(() => _selectedItem = null);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: ErrorMessageWidget(message: message),
      ),
    );
  }

  Future<void> _handleBuy(_ShopDisplayItem item) async {
    setState(() => _buyingItemId = item.shopItemId);
    try {
      final resp = await _repository.buyShopItem(item.shopItemId);
      if (resp.success) {
        final data = resp.data;
        int? newCoins;
        if (data is Map) {
          if (data['wallet'] is Map && data['wallet']['coins'] is int) {
            newCoins = data['wallet']['coins'] as int;
          } else if (data['coins'] is int) {
            newCoins = data['coins'] as int;
          } else if (data['user'] is Map && data['user']['coins'] is int) {
            newCoins = data['user']['coins'] as int;
          }
        }

        final provider = context.read<GameStateProvider>();
        if (newCoins != null && provider.user != null) {
          final old = provider.user!;
          provider.setUser(GameUser(
            name: old.name,
            level: old.level,
            steps: old.steps,
            coins: newCoins,
            email: old.email,
            id: old.id,
            joinDate: old.joinDate,
            bio: old.bio,
            gender: old.gender,
            dob: old.dob,
            avatarUrl: old.avatarUrl,
          ));
        } else {
          // Fallback: locally deduct price
          await context.read<GameStateProvider>().buyShopItem(price: item.price);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mua thành công: ${item.name}')),
          );
        }
      } else {
        if (mounted) {
          _showError('Mua thất bại: ${resp.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi khi mua: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _buyingItemId = null);
    }
  }

  String _formatMoney(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final mutedForeground = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigation(context),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cửa Hàng',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _items.isEmpty
                            ? Center(
                                child: _errorMessage != null
                                    ? ErrorMessageWidget(
                                        message: _errorMessage!,
                                      )
                                    : Text(
                                        'Không có shop item nào.',
                                        style: TextStyle(color: mutedForeground),
                                      ),
                              )
                            : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return InkWell(
                                    onTap: () => _openDetail(item),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: accent.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: item.image != null && item.image!.isNotEmpty
                                                  ? Image.network(item.image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: accent))
                                                  : Icon(Icons.shopping_bag_outlined, color: accent),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: foreground,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (item.itemTypeName != null)
                                                  Text(
                                                    item.itemTypeName!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: mutedForeground,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formatMoney(item.price),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: foreground,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              SizedBox(
                                                height: 34,
                                                child: _buyingItemId == item.shopItemId
                                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : ElevatedButton(
                                                        onPressed: () => _handleBuy(item),
                                                        style: ElevatedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        child: const Text('Mua'),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            if (_selectedItem != null)
              GestureDetector(
                onTap: _closeDetail,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedItem!.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: foreground,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _closeDetail,
                                  icon: Icon(Icons.close, color: mutedForeground),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedItem!.itemTypeName != null)
                              _buildDetailRow('Loại', _selectedItem!.itemTypeName!, foreground, mutedForeground),
                            const SizedBox(height: 8),
                            _buildDetailRow('Giá bán', _formatMoney(_selectedItem!.price), foreground, mutedForeground),
                            const SizedBox(height: 8),
                            if (_selectedItem!.description != null)
                              _buildDetailRow('Mô tả', _selectedItem!.description!, foreground, mutedForeground),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color foreground, Color mutedForeground) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBgColor = isDark ? const Color(0xFF25332A) : const Color(0xFFE5DCCF);
    final activeBgColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final activeIconColor = isDark ? const Color(0xFF1E2E24) : const Color(0xFFFFF8F0);
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
                iconWidget: Icon(Icons.bolt_rounded, size: 22, color: inactiveColor),
                label: 'Cộng Đồng',
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
                iconWidget: Icon(Icons.backpack_outlined, size: 22, color: inactiveColor),
                label: 'Túi Đồ',
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/inventory'),
              ),
              _buildNavItem(
                iconWidget: Icon(Icons.storefront_outlined, size: 22, color: inactiveColor),
                label: 'Cửa Hàng',
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
                      child: Icon(Icons.home_rounded, size: 28, color: activeIconColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trang Chủ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
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
    canvas.drawLine(Offset(w * 0.25, h * 0.75), Offset(w * 0.75, h * 0.25), paint);
    canvas.drawLine(Offset(w * 0.2, h * 0.55), Offset(w * 0.45, h * 0.8), paint);
    canvas.drawLine(Offset(w * 0.75, h * 0.75), Offset(w * 0.25, h * 0.25), paint);
    canvas.drawLine(Offset(w * 0.8, h * 0.55), Offset(w * 0.55, h * 0.8), paint);
  }

  @override
  bool shouldRepaint(covariant _SwordsPainter oldDelegate) => oldDelegate.color != color;
}
