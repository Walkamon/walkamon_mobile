import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/localization/translation_resolver.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/pvp_item_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/pvp_provider.dart';
import '../../../widgets/common/game_back_button.dart';
import '../../../widgets/common/game_notification_dialog.dart';
import 'pvp_asset_resolver.dart';

class PvpLoadoutScreen extends StatefulWidget {
  const PvpLoadoutScreen({
    super.key,
    required this.pvpProvider,
    required this.backgroundAsset,
  });

  final PvpProvider pvpProvider;
  final String backgroundAsset;

  @override
  State<PvpLoadoutScreen> createState() => _PvpLoadoutScreenState();
}

class _PvpLoadoutScreenState extends State<PvpLoadoutScreen> {
  final Map<int, String> _draft = <int, String>{};
  Map<int, String> _saved = <int, String>{};
  String? _pendingReplacementItemId;
  bool _seeded = false;

  bool get _dirty => !_sameSelection(_draft, _saved);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await widget.pvpProvider.refreshPvpLoadout();
    if (!mounted) return;
    _seedFromProvider(force: true);
  }

  void _seedFromProvider({bool force = false}) {
    if (_seeded && !force) return;
    final selected = <int, String>{
      for (final slot in widget.pvpProvider.configuredLoadoutSlots)
        if (slot.itemId?.isNotEmpty == true) slot.slotNo: slot.itemId!,
    };
    setState(() {
      _draft
        ..clear()
        ..addAll(selected);
      _saved = Map<int, String>.from(selected);
      _pendingReplacementItemId = null;
      _seeded = true;
    });
  }

  static bool _sameSelection(Map<int, String> a, Map<int, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  PvpAvailableLoadoutItem? _itemById(String? itemId) {
    if (itemId == null) return null;
    for (final item in widget.pvpProvider.availableLoadoutItems) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }

  void _toggleItem(PvpAvailableLoadoutItem item) {
    if (!item.isOwned || widget.pvpProvider.isLoadoutLocked) return;
    final equippedEntry = _draft.entries
        .where((entry) => entry.value == item.itemId)
        .firstOrNull;
    if (equippedEntry != null) {
      setState(() {
        _draft.remove(equippedEntry.key);
        _pendingReplacementItemId = null;
      });
      return;
    }

    final slotLimit = widget.pvpProvider.loadoutSlotLimit.clamp(1, 2);
    for (var slotNo = 1; slotNo <= slotLimit; slotNo++) {
      if (!_draft.containsKey(slotNo)) {
        setState(() {
          _draft[slotNo] = item.itemId;
          _pendingReplacementItemId = null;
        });
        return;
      }
    }
    setState(() => _pendingReplacementItemId = item.itemId);
  }

  void _selectReplacementSlot(int slotNo) {
    final pending = _pendingReplacementItemId;
    if (pending == null || widget.pvpProvider.isLoadoutLocked) return;
    setState(() {
      _draft[slotNo] = pending;
      _pendingReplacementItemId = null;
    });
  }

  Future<void> _save() async {
    final slots =
        _draft.entries
            .map((entry) => _itemById(entry.value)?.toSlot(entry.key))
            .whereType<PvpLoadoutSlot>()
            .toList(growable: false)
          ..sort((a, b) => a.slotNo.compareTo(b.slotNo));
    final saved = await widget.pvpProvider.savePvpLoadout(slots);
    if (!mounted || !saved) return;
    _seedFromProvider(force: true);
    showGameNotificationDialog(
      context,
      message: AppLocalizations.of(context).pvpLoadoutSaved,
      isSuccess: true,
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.authCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.woodDeep, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.iconShoppingBag, width: 58, height: 58),
                  const SizedBox(height: 12),
                  Text(
                    l10n.pvpLoadoutDiscardTitle,
                    style: const TextStyle(
                      color: AppColors.woodDeep,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pvpLoadoutDiscardBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkBrown),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(l10n.pvpLoadoutKeepEditing),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(l10n.pvpLoadoutDiscard),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Future<void> _goBack() async {
    if (await _confirmDiscard() && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_goBack());
      },
      child: Scaffold(
        backgroundColor: AppColors.creamLight,
        body: AnimatedBuilder(
          animation: widget.pvpProvider,
          builder: (context, _) {
            final provider = widget.pvpProvider;
            final failure = provider.loadoutFailure;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  widget.backgroundAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
                Container(color: Colors.black.withValues(alpha: 0.24)),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                        child: Row(
                          children: [
                            GameBackButton(
                              semanticLabel: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                              onPressed: _goBack,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.pvpLoadoutTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    l10n.pvpLoadoutSubtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: provider.isLoadoutLoading && !_seeded
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.goldLight,
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  116,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildEquippedPanel(context),
                                    if (failure != null) ...[
                                      const SizedBox(height: 12),
                                      _LoadoutMessageCard(
                                        message:
                                            TranslationResolver.resolveFailure(
                                              context,
                                              failure,
                                            ),
                                        isError: true,
                                        onRetry: _load,
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Text(
                                      l10n.pvpLoadoutAvailableTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black54,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (provider.availableLoadoutItems.isEmpty)
                                      _buildNoItems(context)
                                    else
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                              // Keep enough vertical room for the localized
                                              // description and quantity row on compact phones.
                                              childAspectRatio: 0.75,
                                            ),
                                        itemCount: provider
                                            .availableLoadoutItems
                                            .length,
                                        itemBuilder: (context, index) {
                                          final item = provider
                                              .availableLoadoutItems[index];
                                          final equippedSlot = _draft.entries
                                              .where(
                                                (entry) =>
                                                    entry.value == item.itemId,
                                              )
                                              .map((entry) => entry.key)
                                              .firstOrNull;
                                          return _PvpItemCard(
                                            item: item,
                                            equippedSlot: equippedSlot,
                                            selectedForReplacement:
                                                _pendingReplacementItemId ==
                                                item.itemId,
                                            onTap: () => _toggleItem(item),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.paddingOf(context).bottom + 14,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          _dirty &&
                              !provider.isLoadoutSaving &&
                              !provider.isLoadoutLocked
                          ? _save
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldLight,
                        foregroundColor: AppColors.woodDeep,
                        disabledBackgroundColor: AppColors.creamLight
                            .withValues(alpha: 0.7),
                        side: const BorderSide(
                          color: AppColors.woodDeep,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: provider.isLoadoutSaving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Image.asset(
                              AppAssets.iconSave,
                              width: 28,
                              height: 28,
                            ),
                      label: Text(
                        provider.isLoadoutLocked
                            ? l10n.pvpLoadoutLocked
                            : l10n.pvpLoadoutSave,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEquippedPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final replacementMode = _pendingReplacementItemId != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.woodDeep, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pvpLoadoutSummary(
                  _draft.length,
                  widget.pvpProvider.loadoutSlotLimit,
                ),
                style: const TextStyle(
                  color: AppColors.woodDeep,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Image.asset(AppAssets.iconShoppingBag, width: 36, height: 36),
            ],
          ),
          if (replacementMode) ...[
            const SizedBox(height: 6),
            Text(
              l10n.pvpLoadoutChooseReplacement,
              style: const TextStyle(
                color: AppColors.oliveDeep,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              for (var slotNo = 1; slotNo <= 2; slotNo++) ...[
                if (slotNo > 1) const SizedBox(width: 10),
                Expanded(
                  child: _EquippedSlotCard(
                    slotNo: slotNo,
                    item: _itemById(_draft[slotNo]),
                    replacementMode: replacementMode,
                    onTap: () => _selectReplacementSlot(slotNo),
                    onRemove: _draft.containsKey(slotNo)
                        ? () => setState(() {
                            _draft.remove(slotNo);
                            _pendingReplacementItemId = null;
                          })
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _LoadoutMessageCard(
      message: l10n.pvpLoadoutNoItems,
      asset: AppAssets.iconShoppingBag,
      actionLabel: l10n.pvpLoadoutGoToShop,
      onAction: () => Navigator.pushNamed(context, '/shop'),
    );
  }
}

class _EquippedSlotCard extends StatelessWidget {
  const _EquippedSlotCard({
    required this.slotNo,
    required this.item,
    required this.replacementMode,
    required this.onTap,
    this.onRemove,
  });

  final int slotNo;
  final PvpAvailableLoadoutItem? item;
  final bool replacementMode;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = item == null
        ? null
        : PvpAssetResolver.itemIcon(item!.presentationCode ?? '');
    return Semantics(
      button: replacementMode,
      label: l10n.pvpLoadoutSlot(slotNo),
      child: InkWell(
        onTap: replacementMode ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: replacementMode
                ? AppColors.goldLight.withValues(alpha: 0.28)
                : AppColors.creamLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: replacementMode ? AppColors.gold : AppColors.woodLight,
              width: replacementMode ? 2.4 : 1.4,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.pvpLoadoutSlot(slotNo),
                    style: const TextStyle(
                      color: AppColors.woodDeep,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (icon != null)
                    Image.asset(icon, width: 64, height: 64)
                  else
                    Opacity(
                      opacity: 0.46,
                      child: Image.asset(
                        AppAssets.iconUseCharm,
                        width: 56,
                        height: 56,
                      ),
                    ),
                  Text(
                    item == null
                        ? l10n.pvpLoadoutEmptySlot
                        : _itemName(l10n, item!.itemKind),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.inkBrown,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (onRemove != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          AppAssets.iconRemove,
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PvpItemCard extends StatelessWidget {
  const _PvpItemCard({
    required this.item,
    required this.equippedSlot,
    required this.selectedForReplacement,
    required this.onTap,
  });

  final PvpAvailableLoadoutItem item;
  final int? equippedSlot;
  final bool selectedForReplacement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = PvpAssetResolver.itemIcon(item.presentationCode ?? '');
    final isSelected = equippedSlot != null || selectedForReplacement;
    final durationSeconds = item.durationMs / 1000;
    return Semantics(
      button: true,
      enabled: item.isOwned,
      selected: isSelected,
      label: _itemName(l10n, item.itemKind),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.isOwned ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.authCard.withValues(
                alpha: item.isOwned ? 0.97 : 0.72,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.woodLight,
                width: isSelected ? 2.5 : 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Opacity(
              opacity: item.isOwned ? 1 : 0.48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: icon == null
                        ? Image.asset(
                            AppAssets.iconUseCharm,
                            width: 68,
                            height: 68,
                          )
                        : Image.asset(icon, width: 76, height: 76),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _itemName(l10n, item.itemKind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.woodDeep,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(
                      _itemDescription(l10n, item.itemKind),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkBrown,
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.targetCode == 'opponent'
                        ? l10n.pvpItemTargetOpponent
                        : l10n.pvpItemTargetSelf,
                    style: const TextStyle(
                      color: AppColors.oliveDeep,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.durationMs > 0)
                    Text(
                      l10n.pvpItemDurationSeconds(durationSeconds),
                      style: const TextStyle(
                        color: AppColors.inkBrown,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.pvpLoadoutQuantity(item.quantity),
                          style: const TextStyle(
                            color: AppColors.woodDeep,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (equippedSlot != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.leafLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.pvpLoadoutSlot(equippedSlot!),
                            style: const TextStyle(
                              color: AppColors.oliveDeep,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
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
    );
  }
}

class _LoadoutMessageCard extends StatelessWidget {
  const _LoadoutMessageCard({
    required this.message,
    this.asset,
    this.isError = false,
    this.actionLabel,
    this.onAction,
    this.onRetry,
  });

  final String message;
  final String? asset;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError ? Colors.red.shade300 : AppColors.woodLight,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (asset != null) Image.asset(asset!, width: 64, height: 64),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isError ? Colors.red.shade900 : AppColors.inkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRetry != null || onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry ?? onAction,
              child: Text(
                actionLabel ??
                    MaterialLocalizations.of(
                      context,
                    ).refreshIndicatorSemanticLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _itemName(AppLocalizations l10n, PvpItemKind kind) => switch (kind) {
  PvpItemKind.haste => l10n.pvpItemHasteName,
  PvpItemKind.slow => l10n.pvpItemSlowName,
  PvpItemKind.cleanse => l10n.pvpItemCleanseName,
  PvpItemKind.shield => l10n.pvpItemShieldName,
  PvpItemKind.unknown => l10n.pvpLoadoutTitle,
};

String _itemDescription(AppLocalizations l10n, PvpItemKind kind) =>
    switch (kind) {
      PvpItemKind.haste => l10n.pvpItemHasteDescription,
      PvpItemKind.slow => l10n.pvpItemSlowDescription,
      PvpItemKind.cleanse => l10n.pvpItemCleanseDescription,
      PvpItemKind.shield => l10n.pvpItemShieldDescription,
      PvpItemKind.unknown => '',
    };
