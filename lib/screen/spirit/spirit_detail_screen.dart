import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';

class SpiritDetailScreen extends StatefulWidget {
  const SpiritDetailScreen({super.key});

  @override
  State<SpiritDetailScreen> createState() => _SpiritDetailScreenState();
}

class _SpiritDetailScreenState extends State<SpiritDetailScreen> {
  String _activeTab = 'stats';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showEvolutionAnimation = false;
  bool _isEvolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final gameState = context.read<GameStateProvider>();
      await gameState.fetchPetStatus();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _handleAction(
    Future<bool> Function() action,
    String successMessage,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final success = await action();

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleEvolveClick() async {
    if (_showEvolutionAnimation) return;
    setState(() => _showEvolutionAnimation = true);

    await Future.delayed(const Duration(milliseconds: 2400));

    if (!mounted) return;

    setState(() {
      _showEvolutionAnimation = false;
      _isEvolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Consumer<GameStateProvider>(
      builder: (context, gameState, _) {
        final bonding = gameState.bondingLevel.clamp(0, 100);
        final energy = gameState.spiritEnergy.clamp(0, 100);
        final health = gameState.spiritHealth.clamp(0, 100);
        final level = gameState.spiritLevel;
        final exp = gameState.spiritExp.clamp(0, 100);
        final spiritName = gameState.spiritName;
        final isEvolved = _isEvolved || level >= 15;

        final usableItems = <_SupportItemData>[
          _SupportItemData(
            name: l10n.spiritRecoveryPotion,
            count: 3,
            description: l10n.spiritBondBonus(20),
            icon: Icons.auto_awesome,
            iconColor: AppColors.lightBond,
            bgColor: AppColors.lightBond.withOpacity(0.12),
          ),
          _SupportItemData(
            name: l10n.shopCurrency,
            count: 15,
            description: l10n.spiritEnergyBonus(30),
            icon: Icons.flash_on_rounded,
            iconColor: AppColors.lightDew,
            bgColor: AppColors.lightDew.withOpacity(0.12),
          ),
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primary.withOpacity(0.10), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40,
                left: -60,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(
                                  0.85,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                l10n.spiritDetailTitle(spiritName),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 42),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Center(
                                      child: Container(
                                        width: 220,
                                        height: 220,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              primary.withOpacity(0.20),
                                              primary.withOpacity(0.04),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.spa_rounded,
                                                size: 90,
                                                color: primary,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                spiritName,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface
                                            .withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
                                            blurRadius: 18,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            spiritName,
                                                            style: theme
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: primary
                                                                .withOpacity(
                                                                  0.10,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            l10n.spiritLevel(
                                                              isEvolved
                                                                  ? 16
                                                                  : level,
                                                            ),
                                                            style: theme
                                                                .textTheme
                                                                .labelMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      primary,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        _TagChip(
                                                          label: l10n
                                                              .seedPath3Name,
                                                        ),
                                                        _TagChip(
                                                          label: l10n
                                                              .spiritPlantType,
                                                        ),
                                                        _TagChip(
                                                          label: isEvolved
                                                              ? l10n.spiritStageLeaf
                                                              : l10n.spiritStageSprout,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.darkMuted
                                                  : AppColors.lightMuted,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _TabButton(
                                                    label: l10n.spiritStatsTab,
                                                    active:
                                                        _activeTab == 'stats',
                                                    onTap: () => setState(
                                                      () =>
                                                          _activeTab = 'stats',
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _TabButton(
                                                    label:
                                                        l10n.spiritEvolutionTab,
                                                    active:
                                                        _activeTab ==
                                                        'evolution',
                                                    onTap: () => setState(
                                                      () => _activeTab =
                                                          'evolution',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              child: _activeTab == 'stats'
                                                  ? _buildStatsContent(
                                                      theme: theme,
                                                      primary: primary,
                                                      mutedFg: mutedFg,
                                                      bonding: bonding,
                                                      energy: energy,
                                                      health: health,
                                                      exp: exp,
                                                      usableItems: usableItems,
                                                      isDark: isDark,
                                                    )
                                                  : _buildEvolutionContent(
                                                      theme: theme,
                                                      primary: primary,
                                                      mutedFg: mutedFg,
                                                      level: level,
                                                      bonding: bonding,
                                                      isEvolved: isEvolved,
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              if (_showEvolutionAnimation) _buildEvolutionOverlay(primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsContent({
    required ThemeData theme,
    required Color primary,
    required Color mutedFg,
    required int bonding,
    required int energy,
    required int health,
    required int exp,
    required List<_SupportItemData> usableItems,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      key: const ValueKey('stats'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatRow(
            title: l10n.spiritLifeForceExp,
            value: '$exp/100',
            progress: exp / 100,
            color: AppColors.lightLife,
          ),
          const SizedBox(height: 10),
          _StatRow(
            title: l10n.bonding,
            value: '$bonding/100',
            progress: bonding / 100,
            color: AppColors.lightBond,
          ),
          const SizedBox(height: 10),
          _StatRow(
            title: l10n.energy,
            value: '$energy/100',
            progress: energy / 100,
            color: AppColors.lightDew,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spiritSupportItems,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...usableItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: item.bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                item.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'x${item.count}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: l10n.spiritTapLumina,
                  icon: Icons.touch_app,
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleAction(
                          () => context.read<GameStateProvider>().tapSpirit(),
                          l10n.spiritTapSuccess,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: l10n.spiritFeed,
                  icon: Icons.restaurant,
                  onPressed: _isSubmitting
                      ? null
                      : () => _handleAction(
                          () => context.read<GameStateProvider>().feedSpirit(),
                          l10n.spiritFeedSuccess,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionContent({
    required ThemeData theme,
    required Color primary,
    required Color mutedFg,
    required int level,
    required int bonding,
    required bool isEvolved,
  }) {
    final l10n = AppLocalizations.of(context);
    final readyForEvolution = level >= 15 && bonding >= 70;

    return SingleChildScrollView(
      key: const ValueKey('evolution'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.spiritEvolutionStages,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _EvolutionStepItem(
                        title: l10n.spiritStageSeed,
                        done: true,
                        active: true,
                      ),
                    ),
                    Expanded(
                      child: _EvolutionStepItem(
                        title: l10n.spiritStageSprout,
                        done: level >= 10,
                        active: level >= 10,
                      ),
                    ),
                    Expanded(
                      child: _EvolutionStepItem(
                        title: l10n.spiritStageLeaf,
                        done: isEvolved,
                        active: isEvolved,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.spiritCurrentRequirement(level, bonding),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedFg,
                        ),
                      ),
                    ),
                    if (readyForEvolution)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.spiritReady,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spiritEvolutionHistory,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _HistoryRow(
                  icon: Icons.auto_awesome,
                  title: l10n.spiritHistoryHatched,
                  subtitle: '01/05/2026',
                ),
                _HistoryRow(
                  icon: Icons.shield_outlined,
                  title: l10n.spiritHistorySprout,
                  subtitle: '14/05/2026',
                ),
                if (isEvolved)
                  _HistoryRow(
                    icon: Icons.stars_rounded,
                    title: l10n.spiritHistoryLeaf,
                    subtitle: l10n.notificationsTimeAgoJustNow,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!isEvolved)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.spiritEvolutionConditions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _ConditionCard(
                  text: l10n.spiritReachLevel15,
                  value: '15/15',
                  ok: true,
                ),
                const SizedBox(height: 8),
                _ConditionCard(
                  text: l10n.spiritBondRequirement,
                  value: l10n.spiritMet,
                  ok: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleEvolveClick,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      l10n.spiritEvolveNow,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withOpacity(0.20)),
              ),
              child: Text(
                l10n.spiritMaxEvolution,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvolutionOverlay(Color primary) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1,
      child: Container(
        color: theme.colorScheme.background.withOpacity(0.95),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      primary.withOpacity(0.20),
                      primary.withOpacity(0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).spiritEvolving,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutBack,
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.12),
                    ),
                    child: Center(
                      child: Icon(Icons.spa_rounded, size: 88, color: primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: active
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.title,
    required this.value,
    required this.progress,
    required this.color,
    super.key,
  });

  final String title;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceVariant,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _EvolutionStepItem extends StatelessWidget {
  const _EvolutionStepItem({
    required this.title,
    required this.done,
    required this.active,
    super.key,
  });

  final String title;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? primary : theme.colorScheme.surfaceVariant,
          ),
          child: Icon(
            done ? Icons.check : Icons.circle_outlined,
            size: 16,
            color: done
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
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

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.text,
    required this.value,
    required this.ok,
    super.key,
  });

  final String text;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: ok
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportItemData {
  const _SupportItemData({
    required this.name,
    required this.count,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String name;
  final int count;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}
