import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../pvp_asset_resolver.dart';

class PvpHudSlot {
  const PvpHudSlot({
    required this.itemCode,
    this.cooldownProgress = 0,
    this.enabled = true,
    this.used = false,
    this.pending = false,
    this.quantity,
    this.onTap,
  });

  final String? itemCode;
  final double cooldownProgress;
  final bool enabled;
  final bool used;
  final bool pending;
  final int? quantity;
  final VoidCallback? onTap;
}

/// Compact floating item controls. The old 9-slice board was intentionally
/// removed because it covered the race track and made two items look like a
/// second status bar.
class PvpTwoSlotHud extends StatelessWidget {
  const PvpTwoSlotHud({
    super.key,
    this.left = const PvpHudSlot(itemCode: null, enabled: false),
    this.right = const PvpHudSlot(itemCode: null, enabled: false),
  });

  final PvpHudSlot left;
  final PvpHudSlot right;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SlotButton(slot: left),
          const SizedBox(width: 12),
          _SlotButton(slot: right),
        ],
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({required this.slot});

  final PvpHudSlot slot;

  @override
  Widget build(BuildContext context) {
    final icon = slot.itemCode == null
        ? null
        : PvpAssetResolver.itemIcon(slot.itemCode!);
    final cooldown = slot.cooldownProgress.clamp(0.0, 1.0);

    return Semantics(
      button: true,
      enabled: slot.enabled && !slot.used && !slot.pending,
      label: slot.itemCode == null
          ? 'Empty PvP item slot'
          : 'PvP item ${slot.itemCode}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: slot.enabled && !slot.used && !slot.pending && cooldown <= 0
              ? slot.onTap
              : null,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (icon == null)
                  Container(
                    width: 62,
                    height: 62,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Opacity(
                      opacity: 0.45,
                      child: Image.asset(
                        AppAssets.iconUseCharm,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: slot.enabled && !slot.used ? 1 : 0.42,
                      child: Image.asset(
                        icon,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                if (cooldown > 0)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: cooldown,
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (slot.pending)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (slot.used)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.48),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                if (slot.quantity != null && !slot.used)
                  Positioned(
                    right: 3,
                    bottom: 2,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '${slot.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
