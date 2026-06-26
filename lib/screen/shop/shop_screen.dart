import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/shop_screen_repository.dart';
import '../../providers/game_state_provider.dart';

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
          provider.setUser(provider.user!.copyWith(coins: newCoins));
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mua thất bại: ${resp.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi mua: ${e.toString()}')),
        );
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
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
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
                                child: Text(
                                  _errorMessage ?? 'Không có shop item nào.',
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
}
