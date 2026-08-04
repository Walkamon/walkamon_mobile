import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/audio/app_audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/shop_screen_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/bottom_navigation.dart';
import '../../widgets/common/home_page_backdrop.dart';
import '../../widgets/common/error_message_widget.dart';
import '../../widgets/common/game_notification_dialog.dart';
import '../../widgets/common/game_button_label.dart';

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
  final WalletRepository _walletRepository = WalletRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<_ShopDisplayItem> _items = [];
  _ShopDisplayItem? _selectedItem;
  String? _buyingItemId;
  int _walletBalance = 0;
  bool _isWalletLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopItems();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final wallet = await _walletRepository.getBalance();
      if (!mounted) return;
      final provider = context.read<GameStateProvider>();
      if (provider.user != null && provider.user!.coins != wallet.balance) {
        provider.setUser(provider.user!.copyWith(coins: wallet.balance));
      }
      setState(() {
        _walletBalance = wallet.balance;
        _isWalletLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWalletLoading = false;
      });
    }
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
        _errorMessage = AppLocalizations.of(context).shopNoItems;
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
    showGameNotificationDialog(context, message: message, isSuccess: false);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showGameNotificationDialog(context, message: message, isSuccess: true);
  }

  int? _extractWalletBalance(dynamic data) {
    int? parseValue(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    const balanceKeys = [
      'coins',
      'Coins',
      'balance',
      'Balance',
      'walletBalance',
      'WalletBalance',
      'currentBalance',
      'CurrentBalance',
    ];
    for (final key in balanceKeys) {
      if (map.containsKey(key)) {
        final balance = parseValue(map[key]);
        if (balance != null) return balance;
      }
    }

    const containerKeys = ['wallet', 'Wallet', 'user', 'User', 'data', 'Data'];
    for (final key in containerKeys) {
      final nestedBalance = _extractWalletBalance(map[key]);
      if (nestedBalance != null) return nestedBalance;
    }
    return null;
  }

  Future<void> _handleBuy(_ShopDisplayItem item) async {
    if (_buyingItemId != null) return;

    AppAudioService.instance.suppressNextTabSound();
    setState(() => _buyingItemId = item.shopItemId);
    try {
      final resp = await _repository.buyShopItem(item.shopItemId);
      if (!mounted) return;

      if (resp.success) {
        unawaited(AppAudioService.instance.playReward());
        final provider = context.read<GameStateProvider>();
        final serverBalance = _extractWalletBalance(resp.data);
        final currentBalance = _isWalletLoading
            ? (provider.user?.coins ?? _walletBalance)
            : _walletBalance;
        final updatedBalance =
            serverBalance ??
            (currentBalance >= item.price ? currentBalance - item.price : 0);

        if (provider.user != null) {
          provider.setUser(provider.user!.copyWith(coins: updatedBalance));
        }

        setState(() {
          _walletBalance = updatedBalance;
          _isWalletLoading = false;
          _selectedItem = null;
          _buyingItemId = null;
        });

        _showSuccess(AppLocalizations.of(context).shopBuySuccess(item.name));
        unawaited(_loadWalletBalance());
      } else {
        _showError(AppLocalizations.of(context).shopBuyFailed(resp.message));
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context).shopBuyError(e.toString()));
      }
    } finally {
      if (mounted && _buyingItemId != null) {
        setState(() => _buyingItemId = null);
      }
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final mutedForeground = isDark
        ? AppColors.darkForeground.withValues(alpha: 0.82)
        : AppColors.lightForeground.withValues(alpha: 0.84);
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          bottomNavigationBar: const BottomNavigation(),
          body: HomePageBackdrop(
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ShopPanel(
                            title: l10n.shopTitle,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: _ShopWalletPill(
                                    value: _isWalletLoading
                                        ? '...'
                                        : _formatMoney(_walletBalance),
                                    isDark: isDark,
                                  ),
                                ),
                                Positioned.fill(
                                  top: 42,
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : _ShopGrid(
                                          items: _items,
                                          borderColor: borderColor,
                                          accent: accent,
                                          isDark: isDark,
                                          formatMoney: _formatMoney,
                                          onSelect: _openDetail,
                                          emptyMessage: _items.isEmpty
                                              ? (_errorMessage ??
                                                    l10n.shopNoItems)
                                              : null,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedItem != null)
          Positioned.fill(
            child: _ShopDetailModal(
              item: _selectedItem!,
              isDark: isDark,
              cardColor: cardColor,
              borderColor: borderColor,
              foreground: foreground,
              mutedForeground: mutedForeground,
              accent: accent,
              isBuying: _buyingItemId == _selectedItem!.shopItemId,
              typeLabel: l10n.shopType,
              priceLabel: l10n.shopPrice,
              noDescription: l10n.inventoryNoDescription,
              closeLabel: l10n.close,
              buyLabel: l10n.shopBuy,
              processingLabel: l10n.processing,
              formatMoney: _formatMoney,
              onClose: _closeDetail,
              onBuy: () => _handleBuy(_selectedItem!),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color foreground,
    Color mutedForeground,
  ) {
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

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

// ── Dewdrop Icon (SVG → CustomPaint) ────────────────────────────────────
class _ShopWalletPill extends StatelessWidget {
  const _ShopWalletPill({required this.value, required this.isDark});

  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMuted : AppColors.creamLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.wood,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
            ),
          ),
          const SizedBox(width: 7),
          Image.asset(
            AppAssets.iconDewDrop,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const _DewdropIcon(size: 19, color: AppColors.lightDew),
          ),
        ],
      ),
    );
  }
}

class _ShopDetailModal extends StatelessWidget {
  const _ShopDetailModal({
    required this.item,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.foreground,
    required this.mutedForeground,
    required this.accent,
    required this.isBuying,
    required this.typeLabel,
    required this.priceLabel,
    required this.noDescription,
    required this.closeLabel,
    required this.buyLabel,
    required this.processingLabel,
    required this.formatMoney,
    required this.onClose,
    required this.onBuy,
  });

  final _ShopDisplayItem item;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color accent;
  final bool isBuying;
  final String typeLabel;
  final String priceLabel;
  final String noDescription;
  final String closeLabel;
  final String buyLabel;
  final String processingLabel;
  final String Function(int value) formatMoney;
  final VoidCallback onClose;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final hasImage = item.image != null && item.image!.trim().isNotEmpty;
    final description = item.description?.trim();

    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.42),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {},
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
                                color: AppColors.woodDeep.withValues(
                                  alpha: 0.24,
                                ),
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
                                width: 104,
                                height: 104,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.wood.withValues(
                                      alpha: 0.55,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: hasImage
                                    ? Image.network(
                                        item.image!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => AppIcon(
                                          Icons.shopping_bag_outlined,
                                          asset: AppAssets.iconShoppingBag,
                                          size: 50,
                                          color: accent,
                                        ),
                                      )
                                    : AppIcon(
                                        Icons.shopping_bag_outlined,
                                        asset: AppAssets.iconShoppingBag,
                                        size: 50,
                                        color: accent,
                                      ),
                              ),
                              const SizedBox(height: 18),
                              GameButtonLabel(
                                item.name,
                                fontSize: 23,
                                color: isDark ? foreground : AppColors.woodDeep,
                                outlineColor: isDark
                                    ? cardColor
                                    : AppColors.creamLight,
                                outlineWidth: 3,
                                maxLines: 2,
                              ),
                              if (item.itemTypeName?.trim().isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.leafLight.withValues(
                                      alpha: 0.42,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.wood.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '$typeLabel: ${item.itemTypeName!.trim()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? foreground
                                          : AppColors.woodDeep,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.creamLight,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.wood.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$priceLabel: ${formatMoney(item.price)}',
                                      style: const TextStyle(
                                        color: AppColors.woodDeep,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Image.asset(
                                      AppAssets.iconDewDrop,
                                      width: 21,
                                      height: 21,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                description?.isNotEmpty == true
                                    ? description!
                                    : noDescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? mutedForeground
                                      : AppColors.inkBrown,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 26),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ShopModalButton(
                                      label: closeLabel,
                                      backgroundColor: isDark
                                          ? AppColors.darkMuted
                                          : AppColors.buttonSecondary,
                                      foregroundColor: isDark
                                          ? foreground
                                          : AppColors.woodDeep,
                                      onPressed: onClose,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ShopModalButton(
                                      label: isBuying
                                          ? processingLabel
                                          : buyLabel,
                                      backgroundColor: isDark
                                          ? AppColors.darkAccent
                                          : AppColors.buttonYellow,
                                      foregroundColor: isDark
                                          ? AppColors.darkPrimaryForeground
                                          : AppColors.buttonText,
                                      onPressed: isBuying ? null : onBuy,
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopModalButton extends StatelessWidget {
  const _ShopModalButton({
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

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({required this.title, required this.child});

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
              color: AppColors.leafLight.withValues(alpha: 0.96),
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
              color: AppColors.authCard.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppColors.wood, width: 1.5),
            ),
            child: child,
          ),
        ),
        Positioned(
          top: 0,
          left: 35,
          right: 35,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(minWidth: 176),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              child: GameButtonLabel(title, fontSize: 17, outlineWidth: 3),
            ),
          ),
        ),
        const Positioned(
          left: -5,
          top: 16,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(68, 68),
              painter: _ShopFloralPainter(),
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
                painter: _ShopFloralPainter(showFlower: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopGrid extends StatelessWidget {
  const _ShopGrid({
    required this.items,
    required this.borderColor,
    required this.accent,
    required this.isDark,
    required this.formatMoney,
    required this.onSelect,
    required this.emptyMessage,
  });

  final List<_ShopDisplayItem> items;
  final Color borderColor;
  final Color accent;
  final bool isDark;
  final String Function(int value) formatMoney;
  final ValueChanged<_ShopDisplayItem> onSelect;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final slotCount = items.length > 20 ? items.length : 20;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 300 ? 4 : 3;
        return Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 72),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.82,
              ),
              itemCount: slotCount,
              itemBuilder: (context, index) {
                if (index >= items.length) {
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
                    ),
                  );
                }

                final item = items[index];
                final hasImage =
                    item.image != null && item.image!.trim().isNotEmpty;
                return Material(
                  color: isDark
                      ? AppColors.darkMuted
                      : AppColors.authCard.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelect(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(5, 6, 5, 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.wood.withValues(alpha: 0.72),
                          width: 1.4,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: hasImage
                                ? Image.network(
                                    item.image!,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => AppIcon(
                                      Icons.shopping_bag_outlined,
                                      asset: AppAssets.iconShoppingBag,
                                      size: 38,
                                      color: accent,
                                    ),
                                  )
                                : AppIcon(
                                    Icons.shopping_bag_outlined,
                                    asset: AppAssets.iconShoppingBag,
                                    size: 38,
                                    color: accent,
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.creamLight,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: AppColors.wood.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    formatMoney(item.price),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.woodDeep,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  AppAssets.iconDewDrop,
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (emptyMessage != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.authCard.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.wood),
                  ),
                  child: Text(
                    emptyMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.woodDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShopFloralPainter extends CustomPainter {
  const _ShopFloralPainter({this.showFlower = false});

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
    final edge = Paint()
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
      canvas.drawOval(rect, edge);
      canvas.restore();
    }

    drawLeaf(Offset(size.width * 0.28, size.height * 0.68), -0.65, 21, 11);
    drawLeaf(Offset(size.width * 0.43, size.height * 0.53), 0.75, 22, 11);
    drawLeaf(Offset(size.width * 0.6, size.height * 0.35), -0.62, 20, 10);

    if (showFlower) {
      final center = Offset(size.width * 0.7, size.height * 0.24);
      final petal = Paint()..color = AppColors.blossom;
      for (var i = 0; i < 5; i++) {
        final petalCenter = center + Offset.fromDirection(i * 1.25664, 9);
        canvas.drawCircle(petalCenter, 6.5, petal);
        canvas.drawCircle(petalCenter, 6.5, edge);
      }
      canvas.drawCircle(center, 5, Paint()..color = AppColors.goldLight);
      canvas.drawCircle(center, 5, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _ShopFloralPainter oldDelegate) =>
      oldDelegate.showFlower != showFlower;
}

class _DewdropIcon extends StatelessWidget {
  const _DewdropIcon({this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DewdropPainter(color: color ?? Colors.blue),
    );
  }
}

class _DewdropPainter extends CustomPainter {
  const _DewdropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final sx = size.width / 24;
    final sy = size.height / 24;

    final path = Path()
      ..moveTo(12 * sx, 2.5 * sy)
      ..cubicTo(12 * sx, 2.5 * sy, 4.5 * sx, 9.5 * sy, 4.5 * sx, 14 * sy)
      ..cubicTo(4.5 * sx, 18.14 * sy, 7.86 * sx, 21.5 * sy, 12 * sx, 21.5 * sy)
      ..cubicTo(
        16.14 * sx,
        21.5 * sy,
        19.5 * sx,
        18.14 * sy,
        19.5 * sx,
        14 * sy,
      )
      ..cubicTo(19.5 * sx, 9.5 * sy, 12 * sx, 2.5 * sy, 12 * sx, 2.5 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DewdropPainter oldDelegate) => oldDelegate.color != color;
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
