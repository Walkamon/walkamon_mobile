import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../pvp_asset_resolver.dart';

class PvpHudSlot {
  const PvpHudSlot({
    required this.itemCode,
    this.cooldownProgress = 0,
    this.enabled = true,
    this.onTap,
  });

  final String itemCode;
  final double cooldownProgress;
  final bool enabled;
  final VoidCallback? onTap;
}

/// Two-slot item HUD using the 9-slice frame from the PvP asset pack.
class PvpTwoSlotHud extends StatelessWidget {
  const PvpTwoSlotHud({
    super.key,
    this.left = const PvpHudSlot(itemCode: 'haste'),
    this.right = const PvpHudSlot(itemCode: 'shield'),
  });

  final PvpHudSlot left;
  final PvpHudSlot right;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.pvpTwoSlotHud,
              scale: PvpAssetResolver.hudAssetScale,
              fit: BoxFit.fill,
              centerSlice: PvpAssetResolver.hudCenterSlice,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _SlotButton(slot: left)),
                const SizedBox(width: 20),
                Expanded(child: _SlotButton(slot: right)),
              ],
            ),
          ),
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
    final icon = PvpAssetResolver.itemIcon(slot.itemCode);
    final cooldown = slot.cooldownProgress.clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: slot.enabled && cooldown <= 0 ? slot.onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (icon != null)
                Opacity(
                  opacity: slot.enabled ? 1 : 0.45,
                  child: Image.asset(
                    icon,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              if (cooldown > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
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
            ],
          ),
        ),
      ),
    );
  }
}
