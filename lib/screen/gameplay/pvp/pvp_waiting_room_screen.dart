import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/pvp_provider.dart';
import '../../../widgets/common/game_back_button.dart';
import '../../../widgets/common/game_button_label.dart';
import '../../../widgets/pet_runtime/pet_runtime_preview.dart';
import 'pvp_asset_resolver.dart';
import 'widgets/pvp_modals.dart';

class PvPWaitingRoomScreen extends StatelessWidget {
  final PvpProvider pvpProvider;
  final String activePetAffinityCode;
  final int activePetStageNo;
  final String activePetAnimationType;
  final VoidCallback? onStartMatchmaking;
  final VoidCallback? onCancelMatchmaking;
  final void Function(String userId, String username)? onInviteFriend;
  final VoidCallback onShowIncomingChallenges;
  final VoidCallback onShowMatchHistory;

  const PvPWaitingRoomScreen({
    super.key,
    required this.pvpProvider,
    required this.activePetAffinityCode,
    required this.activePetStageNo,
    this.activePetAnimationType = 'idle',
    required this.onStartMatchmaking,
    required this.onCancelMatchmaking,
    required this.onInviteFriend,
    required this.onShowIncomingChallenges,
    required this.onShowMatchHistory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final mapAsset = PvpAssetResolver.mapForNow(
      pvpProvider.estimatedServerNow(),
    );
    final affinityCode = activePetAffinityCode.trim().isEmpty
        ? pvpProvider.spiritAffinityCode
        : activePetAffinityCode.trim();
    final stageNo = activePetAffinityCode.trim().isEmpty
        ? pvpProvider.petStageNo
        : activePetStageNo;
    final passiveAsset = PvpAssetResolver.passiveForAffinity(affinityCode);
    final displayAffinityLabel = switch (affinityCode.toLowerCase()) {
      'warm_sun' => l10n.pvpAffinityWarmSun,
      'dawn' => l10n.pvpAffinityDawn,
      'moonlight' => l10n.pvpAffinityMoonlight,
      'sprout' => l10n.pvpAffinitySprout,
      _ => l10n.pvpAffinityUnknown,
    };
    final isSearchingForOpponent =
        pvpProvider.matchmakingState == PvpMatchmakingState.waiting;
    final hasEnoughEnergy =
        pvpProvider.currentEnergy >= PvpProvider.pvpEnergyCost;
    final isCompactHeight = MediaQuery.sizeOf(context).height < 900;
    final bottomNavigationClearance = isCompactHeight ? 88.0 : 100.0;
    final petViewportHeight = isCompactHeight ? 128.0 : 178.0;
    final petPreviewHeight = isCompactHeight ? 116.0 : 158.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          mapAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
        Container(color: Colors.black.withValues(alpha: 0.28)),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 8,
            20,
            16,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GameBackButton(
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamed(context, '/home');
                      }
                    },
                  ),
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: cardColor,
                              side: const BorderSide(
                                color: AppColors.woodDeep,
                                width: 2,
                              ),
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(8),
                            ),
                            tooltip: l10n.pvpInvites,
                            onPressed: onShowIncomingChallenges,
                            icon: Image.asset(
                              AppAssets.pvpIconInviteFriend,
                              width: 32,
                              height: 32,
                            ),
                          ),
                          if (pvpProvider.incomingInvites.isNotEmpty)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  numberFormat.format(
                                    pvpProvider.incomingInvites.length,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: cardColor,
                          side: const BorderSide(
                            color: AppColors.woodDeep,
                            width: 2,
                          ),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: l10n.pvpHistory,
                        onPressed: onShowMatchHistory,
                        icon: Image.asset(
                          AppAssets.pvpIconBattleHistory,
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PvpPetPanel(
                          title: pvpProvider.petName,
                          compact: isCompactHeight,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: petViewportHeight,
                                decoration: BoxDecoration(
                                  color: cardColor.withValues(
                                    alpha: 0.52,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.woodLight,
                                    width: 1.2,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PetRuntimePreview(
                                      affinityCode: affinityCode,
                                      stageNo: stageNo,
                                      animationType:
                                          activePetAnimationType.trim().isEmpty
                                          ? 'idle'
                                          : activePetAnimationType.trim(),
                                      compact: true,
                                      height: petPreviewHeight,
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 8,
                                      child: Image.asset(
                                        PvpAssetResolver.rankAsset(),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    if (passiveAsset != null)
                                      Positioned(
                                        left: 10,
                                        top: 8,
                                        child: Image.asset(
                                          passiveAsset,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isCompactHeight ? 5 : 9),
                              _buildStatRow(
                                l10n.pvpTodayStepsLabel,
                                numberFormat.format(pvpProvider.todaySteps),
                                compact: isCompactHeight,
                              ),
                              SizedBox(height: isCompactHeight ? 4 : 6),
                              _buildStatRow(
                                l10n.pvpSpiritAffinityLabel,
                                displayAffinityLabel,
                                compact: isCompactHeight,
                              ),
                              SizedBox(height: isCompactHeight ? 4 : 6),
                              _buildStatRow(
                                l10n.pvpEnergyLabel,
                                '${numberFormat.format(pvpProvider.currentEnergy)}/${numberFormat.format(pvpProvider.maxEnergy)}',
                                compact: isCompactHeight,
                              ),
                              SizedBox(height: isCompactHeight ? 4 : 6),
                              _buildStatRow(
                                l10n.pvpBondLabel,
                                numberFormat.format(pvpProvider.currentBond),
                                compact: isCompactHeight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompactHeight ? 10 : 24),
              if (pvpProvider.matchmakingErrorMessage != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    pvpProvider.matchmakingErrorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (!hasEnoughEnergy) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'PvP requires ${PvpProvider.pvpEnergyCost} energy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                height: isCompactHeight ? 50 : 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkLife : const Color(0xFFF6C95D),
                    foregroundColor: isDark ? AppColors.darkTextOutline : AppColors.woodDeep,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed:
                      pvpProvider.matchmakingState ==
                              PvpMatchmakingState.idle ||
                          pvpProvider.matchmakingState ==
                              PvpMatchmakingState.finished ||
                          pvpProvider.matchmakingState ==
                              PvpMatchmakingState.cancelled
                      ? (hasEnoughEnergy ? onStartMatchmaking : null)
                      : null,
                  child: Text(
                    pvpProvider.matchmakingState ==
                            PvpMatchmakingState.connecting
                        ? l10n.pvpConnecting
                        : pvpProvider.matchmakingState ==
                              PvpMatchmakingState.countdown
                        ? l10n.pvpPreparing
                        : l10n.pvpFindRandomMatch,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompactHeight ? 10 : 16),
              SizedBox(
                width: double.infinity,
                height: isCompactHeight ? 50 : 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: isDark ? AppColors.darkForeground : AppColors.woodDeep,
                    side: const BorderSide(color: AppColors.woodDeep, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: onInviteFriend == null || !hasEnoughEnergy
                      ? null
                      : () {
                          final online = pvpProvider.friendsList
                              .where((f) => f.isOnline)
                              .toList();
                          final offline = pvpProvider.friendsList
                              .where((f) => !f.isOnline)
                              .toList();
                          showFriendsModal(
                            context,
                            online,
                            offline,
                            (userId, username) =>
                                onInviteFriend!(userId, username),
                          );
                        },
                  child: Text(
                    l10n.pvpChallengeFriend,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: bottomNavigationClearance),
            ],
          ),
        ),
        if (isSearchingForOpponent)
          Positioned.fill(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0x990F1A12),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _PvpSearchingModal(
                      title: l10n.pvpSearchingOpponent,
                      cancelLabel: l10n.pvpCancelSearch,
                      onCancel: onCancelMatchmaking,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {bool compact = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 5 : 8),
      decoration: BoxDecoration(
        color: AppColors.creamLight.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.woodLight, width: 1.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.inkBrown,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.woodDeep,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PvpSearchingModal extends StatelessWidget {
  const _PvpSearchingModal({
    required this.title,
    required this.cancelLabel,
    required this.onCancel,
  });

  final String title;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.woodDeep, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.leafLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.oliveDeep, width: 2),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.oliveDeep,
                    backgroundColor: AppColors.creamLight,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GameButtonLabel(
                title,
                fontSize: 20,
                color: AppColors.woodDeep,
                outlineColor: AppColors.creamLight,
                outlineWidth: 3.5,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.creamLight,
                    foregroundColor: AppColors.woodDeep,
                    side: const BorderSide(color: AppColors.woodDeep, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: GameButtonLabel(
                    cancelLabel,
                    fontSize: 16,
                    color: AppColors.woodDeep,
                    outlineColor: AppColors.creamLight,
                    outlineWidth: 2.5,
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

class _PvpPetPanel extends StatelessWidget {
  const _PvpPetPanel({
    required this.title,
    required this.child,
    this.compact = false,
  });

  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.darkMuted : AppColors.leafLight;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: compact ? 20 : 24, bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: panelColor.withValues(alpha: 0.96),
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
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                10,
                compact ? 28 : 34,
                10,
                compact ? 9 : 12,
              ),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.wood, width: 1.5),
              ),
              child: child,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 52,
          right: 52,
          child: Container(
            constraints: const BoxConstraints(minHeight: 47),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.woodLight,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.woodDeep, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDeep.withValues(alpha: 0.24),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: GameButtonLabel(
              title,
              fontSize: 17,
              color: AppColors.buttonText,
              outlineColor: AppColors.woodDeep,
              outlineWidth: 3,
            ),
          ),
        ),
        const Positioned(
          left: -4,
          top: 24,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(46, 46),
              painter: _PvpPanelLeafPainter(),
            ),
          ),
        ),
        const Positioned(
          right: -3,
          bottom: -1,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(50, 50),
              painter: _PvpPanelLeafPainter(flower: true, mirrored: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _PvpPanelLeafPainter extends CustomPainter {
  const _PvpPanelLeafPainter({this.flower = false, this.mirrored = false});

  final bool flower;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrored) {
      canvas.translate(size.width, size.height);
      canvas.rotate(3.14159);
    }

    final stem = Paint()
      ..color = AppColors.oliveDeep
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leafFill = Paint()..color = AppColors.leaf;
    final edge = Paint()
      ..color = AppColors.oliveDeep
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(4, size.height - 5),
      Offset(size.width - 7, 7),
      stem,
    );

    void drawLeaf(Offset center, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: 16, height: 8);
      canvas.drawOval(rect, leafFill);
      canvas.drawOval(rect, edge);
      canvas.restore();
    }

    drawLeaf(Offset(size.width * 0.3, size.height * 0.65), -0.65);
    drawLeaf(Offset(size.width * 0.5, size.height * 0.46), 0.75);
    drawLeaf(Offset(size.width * 0.68, size.height * 0.28), -0.62);

    if (flower) {
      final center = Offset(size.width * 0.72, size.height * 0.22);
      final petal = Paint()..color = AppColors.blossom;
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          center + Offset.fromDirection(i * 1.25664, 6.5),
          4.4,
          petal,
        );
      }
      canvas.drawCircle(center, 3.4, Paint()..color = AppColors.goldLight);
    }
  }

  @override
  bool shouldRepaint(covariant _PvpPanelLeafPainter oldDelegate) =>
      oldDelegate.flower != flower || oldDelegate.mirrored != mirrored;
}
