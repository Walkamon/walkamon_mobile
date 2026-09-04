import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/localization/translation_resolver.dart';
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
import '../../widgets/common/game_notification_dialog.dart';
import '../../widgets/common/game_button_label.dart';
import '../../widgets/common/game_async_state.dart';

@visibleForTesting
class ShopCatalogItem {
  const ShopCatalogItem({
    required this.shopItemId,
    required this.name,
    required this.price,
    required this.isActive,
    this.image,
    this.itemTypeName,
    this.effectTypeCode,
    this.description,
    this.itemNameVi,
    this.itemNameEn,
    this.descriptionVi,
    this.descriptionEn,
  });

  final String shopItemId;
  final String name;
  final int price;
  final bool isActive;
  final String? image;
  final String? itemTypeName;
  final String? effectTypeCode;
  final String? description;
  final String? itemNameVi;
  final String? itemNameEn;
  final String? descriptionVi;
  final String? descriptionEn;
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
  List<ShopCatalogItem> _items = [];
  ShopCatalogItem? _selectedItem;
  String? _buyingItemId;
  int _walletBalance = 0;
  bool _isWalletLoading = true;
  String _selectedCategory = 'all';

  String _categoryOf(ShopCatalogItem item) {
    final effectCode = item.effectTypeCode?.trim().toLowerCase() ?? '';
    if (effectCode.startsWith('pvp_')) return 'pvp';
    if (const {'energy', 'life_force', 'bond'}.contains(effectCode)) {
      return 'care';
    }
    final value =
        '${item.itemTypeName ?? ''} ${item.name} ${item.description ?? ''}'
            .trim()
            .toLowerCase();
    if (value.contains('pvp') ||
        value.contains('battle') ||
        value.contains('đua')) {
      return 'pvp';
    }
    if (value.contains('food') ||
        value.contains('feed') ||
        value.contains('care') ||
        value.contains('chăm') ||
        value.contains('thức ăn')) {
      return 'care';
    }
    return 'other';
  }

  List<String> get _visibleCategories {
    final values = _items.map(_categoryOf).toSet();
    return <String>[
      'all',
      if (values.contains('care')) 'care',
      if (values.contains('pvp')) 'pvp',
      if (values.contains('other')) 'other',
    ];
  }

  ShopCatalogItem _localizedItem(ShopCatalogItem item) {
    final code = item.effectTypeCode?.trim().toLowerCase() ?? '';
    if (code.isEmpty) {
      final english = AppLocalizations.of(context).localeName.startsWith('en');
      return ShopCatalogItem(
        shopItemId: item.shopItemId,
        name: (english ? item.itemNameEn : item.itemNameVi) ?? item.name,
        price: item.price,
        isActive: item.isActive,
        image: item.image,
        itemTypeName: item.itemTypeName,
        effectTypeCode: item.effectTypeCode,
        description:
            (english ? item.descriptionEn : item.descriptionVi) ??
            item.description,
        itemNameVi: item.itemNameVi,
        itemNameEn: item.itemNameEn,
        descriptionVi: item.descriptionVi,
        descriptionEn: item.descriptionEn,
      );
    }
    final l10n = AppLocalizations.of(context);
    final content = switch (code) {
      'pvp_speed_up' => (l10n.pvpItemHasteName, l10n.pvpItemHasteDescription),
      'pvp_speed_down' => (l10n.pvpItemSlowName, l10n.pvpItemSlowDescription),
      'pvp_cleanse' => (
        l10n.pvpItemCleanseName,
        l10n.pvpItemCleanseDescription,
      ),
      'pvp_shield' => (l10n.pvpItemShieldName, l10n.pvpItemShieldDescription),
      'energy' => (l10n.shopEnergyItemName, l10n.shopEnergyItemDescription),
      'life_force' => (
        l10n.shopLifeForceItemName,
        l10n.shopLifeForceItemDescription,
      ),
      'bond' => (l10n.shopBondItemName, l10n.shopBondItemDescription),
      _ => null,
    };
    if (content == null) return item;
    return ShopCatalogItem(
      shopItemId: item.shopItemId,
      name: content.$1,
      price: item.price,
      isActive: item.isActive,
      image: item.image,
      itemTypeName: item.itemTypeName,
      effectTypeCode: item.effectTypeCode,
      description: content.$2,
      itemNameVi: item.itemNameVi,
      itemNameEn: item.itemNameEn,
      descriptionVi: item.descriptionVi,
      descriptionEn: item.descriptionEn,
    );
  }

  List<ShopCatalogItem> get _filteredItems => _selectedCategory == 'all'
      ? _items.map(_localizedItem).toList(growable: false)
      : _items
            .where((item) => _categoryOf(item) == _selectedCategory)
            .map(_localizedItem)
            .toList(growable: false);

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
      final cachedBalance = context.read<GameStateProvider>().user?.coins ?? 0;
      setState(() {
        _walletBalance = cachedBalance;
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
            (item) => ShopCatalogItem(
              shopItemId: item.shopItemId,
              name: item.itemName,
              price: item.priceAmount,
              isActive: item.isActive,
              image: item.image,
              itemTypeName: item.itemTypeName,
              effectTypeCode: item.effectTypeCode,
              description: item.description,
              itemNameVi: item.itemNameVi,
              itemNameEn: item.itemNameEn,
              descriptionVi: item.descriptionVi,
              descriptionEn: item.descriptionEn,
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

  void _openDetail(ShopCatalogItem item) {
    setState(() => _selectedItem = item);
  }

  void _closeDetail() {
    setState(() => _selectedItem = null);
  }

  void _showError(String message) {
    if (!mounted) return;
    showGameNotificationDialog(
      context,
      message: message,
      isSuccess: false,
      region: GameNoticeRegion.shop,
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showGameNotificationDialog(
      context,
      message: message,
      isSuccess: true,
      region: GameNoticeRegion.shop,
    );
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

  Future<void> _handleBuy(ShopCatalogItem item) async {
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
        _showError(TranslationResolver.resolveResponse(context, resp));
      }
    } catch (e) {
      if (mounted) {
        _showError(TranslationResolver.resolveError(context, e));
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
                                      ? Center(
                                          child: GameLoadingIndicator(
                                            label: l10n.loading,
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            _ShopCategoryBar(
                                              categories: _visibleCategories,
                                              selected: _selectedCategory,
                                              labelFor: (category) =>
                                                  switch (category) {
                                                    'care' =>
                                                      l10n.shopCareItems,
                                                    'pvp' => l10n.shopPvpItems,
                                                    'other' =>
                                                      l10n.shopOtherItems,
                                                    _ => l10n.shopAllItems,
                                                  },
                                              onSelected: (category) =>
                                                  setState(
                                                    () => _selectedCategory =
                                                        category,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: ShopCatalog(
                                                items: _filteredItems,
                                                borderColor: borderColor,
                                                accent: accent,
                                                isDark: isDark,
                                                formatMoney: _formatMoney,
                                                onSelect: _openDetail,
                                                emptyMessage: _items.isEmpty
                                                    ? (_errorMessage ??
                                                          l10n.shopNoItems)
                                                    : l10n.shopNoItems,
                                              ),
                                            ),
                                          ],
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
            child: ShopDetailModal(
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
              balanceText: l10n.dailyLoginSuccessBalance(_walletBalance),
              noDescription: l10n.inventoryNoDescription,
              closeLabel: l10n.close,
              buyLabel: l10n.shopBuy,
              processingLabel: l10n.processing,
              unavailableLabel: _isWalletLoading
                  ? l10n.loading
                  : (_selectedItem!.isActive
                        ? l10n.shopNotEnoughDew
                        : l10n.shopUnavailable),
              canBuy:
                  _selectedItem!.isActive &&
                  !_isWalletLoading &&
                  _walletBalance >= _selectedItem!.price,
              formatMoney: _formatMoney,
              onClose: _closeDetail,
              onBuy: () => _handleBuy(_selectedItem!),
            ),
          ),
      ],
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
            errorBuilder: (context, error, stackTrace) =>
                const _DewdropIcon(size: 19, color: AppColors.lightDew),
          ),
        ],
      ),
    );
  }
}

class _ShopCategoryBar extends StatelessWidget {
  const _ShopCategoryBar({
    required this.categories,
    required this.selected,
    required this.labelFor,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final String Function(String category) labelFor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = selected == category;
          final iconAsset = switch (category) {
            'pvp' => AppAssets.iconPvpBattle,
            'care' => AppAssets.iconInventoryNav,
            'other' => AppAssets.iconShoppingBag,
            _ => AppAssets.iconShopNav,
          };
          return Semantics(
            button: true,
            selected: active,
            label: labelFor(category),
            child: Material(
              color: active ? AppColors.buttonGreen : AppColors.creamLight,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onSelected(category),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 88),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? AppColors.oliveDeep : AppColors.wood,
                      width: active ? 2 : 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        iconAsset,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labelFor(category),
                        style: const TextStyle(
                          color: AppColors.woodDeep,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

@visibleForTesting
class ShopDetailModal extends StatelessWidget {
  const ShopDetailModal({
    super.key,
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
    required this.balanceText,
    required this.noDescription,
    required this.closeLabel,
    required this.buyLabel,
    required this.processingLabel,
    this.unavailableLabel = '',
    this.canBuy = true,
    required this.formatMoney,
    required this.onClose,
    required this.onBuy,
  });

  final ShopCatalogItem item;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color foreground;
  final Color mutedForeground;
  final Color accent;
  final bool isBuying;
  final String typeLabel;
  final String priceLabel;
  final String balanceText;
  final String noDescription;
  final String closeLabel;
  final String buyLabel;
  final String processingLabel;
  final String unavailableLabel;
  final bool canBuy;
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
                                    ? _ShopItemArtwork(
                                        item: item,
                                        accent: accent,
                                        size: 84,
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
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    AppAssets.iconDewDrop,
                                    width: 17,
                                    height: 17,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      balanceText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark
                                            ? mutedForeground
                                            : AppColors.inkBrown,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!canBuy && !isBuying) ...[
                                const SizedBox(height: 8),
                                Text(
                                  unavailableLabel,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
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
                                          : (canBuy
                                                ? buyLabel
                                                : unavailableLabel),
                                      backgroundColor: isDark
                                          ? AppColors.darkAccent
                                          : AppColors.buttonYellow,
                                      foregroundColor: isDark
                                          ? AppColors.darkPrimaryForeground
                                          : AppColors.buttonText,
                                      onPressed: isBuying || !canBuy
                                          ? null
                                          : onBuy,
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

@visibleForTesting
class ShopCatalog extends StatelessWidget {
  const ShopCatalog({
    super.key,
    required this.items,
    required this.borderColor,
    required this.accent,
    required this.isDark,
    required this.formatMoney,
    required this.onSelect,
    required this.emptyMessage,
  });

  final List<ShopCatalogItem> items;
  final Color borderColor;
  final Color accent;
  final bool isDark;
  final String Function(int value) formatMoney;
  final ValueChanged<ShopCatalogItem> onSelect;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 250),
          child: Container(
            key: const ValueKey('shop-empty-state'),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkMuted : AppColors.creamLight)
                  .withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.68),
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  Icons.shopping_bag_outlined,
                  asset: AppAssets.iconShoppingBag,
                  size: 58,
                  color: accent,
                ),
                const SizedBox(height: 12),
                Text(
                  emptyMessage ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.woodDeep,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final featured = items.firstWhere(
      (item) => item.isActive,
      orElse: () => items.first,
    );
    final remaining = items
        .where((item) => item.shopItemId != featured.shopItemId)
        .toList(growable: false);

    return CustomScrollView(
      key: const ValueKey('shop-real-catalog'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
            child: _ShopFeaturedCard(
              item: featured,
              accent: accent,
              isDark: isDark,
              formatMoney: formatMoney,
              onSelect: onSelect,
            ),
          ),
        ),
        if (remaining.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 76),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: remaining.length,
              itemBuilder: (context, index) => _ShopItemCard(
                item: remaining[index],
                accent: accent,
                isDark: isDark,
                formatMoney: formatMoney,
                onSelect: onSelect,
              ),
            ),
          ),
        if (remaining.isEmpty)
          const SliverToBoxAdapter(child: SizedBox(height: 76)),
      ],
    );
  }
}

class _ShopFeaturedCard extends StatelessWidget {
  const _ShopFeaturedCard({
    required this.item,
    required this.accent,
    required this.isDark,
    required this.formatMoney,
    required this.onSelect,
  });

  final ShopCatalogItem item;
  final Color accent;
  final bool isDark;
  final String Function(int value) formatMoney;
  final ValueChanged<ShopCatalogItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('shop-featured-${item.shopItemId}'),
      color: isDark ? AppColors.darkMuted : AppColors.creamLight,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => onSelect(item),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 158,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.wood, width: 1.7),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkMuted, AppColors.darkCard]
                  : [AppColors.creamLight, AppColors.panelMuted],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _ShopItemArtwork(item: item, accent: accent, size: 116),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.woodDeep,
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    _ShopPricePill(
                      value: formatMoney(item.price),
                      enabled: item.isActive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.accent,
    required this.isDark,
    required this.formatMoney,
    required this.onSelect,
  });

  final ShopCatalogItem item;
  final Color accent;
  final bool isDark;
  final String Function(int value) formatMoney;
  final ValueChanged<ShopCatalogItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isActive ? 1 : 0.58,
      child: Material(
        key: ValueKey('shop-card-${item.shopItemId}'),
        color: isDark ? AppColors.darkMuted : AppColors.authCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => onSelect(item),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.wood.withValues(alpha: 0.76),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ShopItemArtwork(item: item, accent: accent, size: 92),
                ),
                const SizedBox(height: 7),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.woodDeep,
                    fontSize: 13,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.center,
                  child: _ShopPricePill(
                    value: formatMoney(item.price),
                    enabled: item.isActive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopItemArtwork extends StatelessWidget {
  const _ShopItemArtwork({
    required this.item,
    required this.accent,
    required this.size,
  });

  final ShopCatalogItem item;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.image?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return Center(
        child: AppIcon(
          Icons.shopping_bag_outlined,
          asset: AppAssets.iconShoppingBag,
          size: size * 0.56,
          color: accent,
        ),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => Center(
          child: AppIcon(
            Icons.broken_image_outlined,
            asset: AppAssets.iconShoppingBag,
            size: size * 0.56,
            color: accent,
          ),
        ),
      );
    }
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => Center(
        child: AppIcon(
          Icons.broken_image_outlined,
          asset: AppAssets.iconShoppingBag,
          size: size * 0.56,
          color: accent,
        ),
      ),
    );
  }
}

class _ShopPricePill extends StatelessWidget {
  const _ShopPricePill({required this.value, required this.enabled});

  final String value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: enabled ? AppColors.creamLight : AppColors.panelMuted,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.wood.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.woodDeep,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Image.asset(
            AppAssets.iconDewDrop,
            width: 17,
            height: 17,
            fit: BoxFit.contain,
          ),
        ],
      ),
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
