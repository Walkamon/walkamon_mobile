import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/pet_evolution_models.dart';
import '../../l10n/app_localizations.dart';

class SpiritEvolutionScreen extends StatefulWidget {
  const SpiritEvolutionScreen({
    required this.level,
    required this.bonding,
    required this.initialIsEvolved,
    this.overview,
    this.stages = const <PetEvolutionStageResponse>[],
    this.history = const <PetEvolutionHistoryResponse>[],
    this.isLoading = false,
    this.isSubmitting = false,
    this.onEvolve,
    this.onRefresh,
    this.onEvolved,
    super.key,
  });

  final int level;
  final int bonding;
  final bool initialIsEvolved;
  final PetOverviewResponse? overview;
  final List<PetEvolutionStageResponse> stages;
  final List<PetEvolutionHistoryResponse> history;
  final bool isLoading;
  final bool isSubmitting;
  final Future<bool> Function()? onEvolve;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onEvolved;

  @override
  State<SpiritEvolutionScreen> createState() => _SpiritEvolutionScreenState();
}

class _SpiritEvolutionScreenState extends State<SpiritEvolutionScreen> {
  late bool _isEvolved;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _isEvolved = widget.initialIsEvolved;
  }

  Future<void> _handleEvolveClick() async {
    if (_isAnimating || widget.isSubmitting || widget.onEvolve == null) return;

    _isAnimating = true;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, __, ___) =>
            _EvolutionOverlay(primary: Theme.of(context).colorScheme.primary),
      ),
    );

    if (!mounted) return;

    final success = await widget.onEvolve!();

    if (!mounted) return;

    setState(() {
      _isAnimating = false;
      if (success) {
        _isEvolved = true;
        widget.onEvolved?.call();
      }
    });

    if (success) {
      await widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;
    final mutedFg = theme.brightness == Brightness.dark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final readyForEvolution = widget.overview?.canEvolve ?? widget.level >= 15;
    final currentStage =
        widget.stages.where((stage) => stage.isCurrent).isNotEmpty
        ? widget.stages.firstWhere((stage) => stage.isCurrent)
        : null;
    final bool hasNextStage = (() {
      if (widget.stages.isEmpty) return false;
      final currentIndex = widget.stages.indexWhere((s) => s.isCurrent);
      if (currentIndex == -1) return widget.stages.length > 1;
      return currentIndex < widget.stages.length - 1;
    })();
    final stageDisplayName =
        currentStage?.stageName ?? widget.overview?.stageName ?? '';
    final canEvolve = widget.overview?.canEvolve ?? false;

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
                  children: widget.stages.isEmpty
                      ? [
                          Expanded(
                            child: _EvolutionStepItem(
                              title: stageDisplayName.isNotEmpty
                                  ? stageDisplayName
                                  : l10n.spiritStageSeed,
                              done: true,
                              active: true,
                            ),
                          ),
                        ]
                      : widget.stages.map((stage) {
                          final index = widget.stages.indexOf(stage);
                          // Consider a stage "done" if it was unlocked previously
                          // or the whole pet has already evolved. The currently
                          // active stage is highlighted (bright). If there is no
                          // explicit current stage, highlight the first one.
                          final isDone = stage.isUnlocked || _isEvolved;
                          final isActive =
                              stage.isCurrent ||
                              (index == 0 &&
                                  !widget.stages.any((item) => item.isCurrent));
                          return Expanded(
                            child: _EvolutionStepItem(
                              title: stage.stageName,
                              done: isDone,
                              active: isActive,
                            ),
                          );
                        }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.overview != null
                            ? 'Stage hiện tại: $stageDisplayName • Cấp ${widget.overview!.level}'
                            : l10n.spiritCurrentRequirement(
                                widget.level,
                                widget.bonding,
                              ),
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
                if (widget.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (widget.history.isEmpty)
                  Text(
                    'Chưa có lịch sử tiến hóa.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: mutedFg),
                  )
                else
                  ...widget.history.map((item) {
                    return _HistoryRow(
                      icon: Icons.auto_awesome,
                      title: item.stageName,
                      subtitle: item.evolvedAt.isNotEmpty
                          ? item.evolvedAt
                          : 'Cấp ${item.level}',
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!_isEvolved)
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
                  value: '${widget.overview?.level ?? widget.level}/15',
                  ok: (widget.overview?.level ?? widget.level) >= 15,
                ),
                const SizedBox(height: 8),
                _ConditionCard(
                  text: l10n.spiritBondRequirement,
                  value: l10n.spiritMet,
                  ok: widget.bonding >= 70,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (widget.isSubmitting ||
                            !canEvolve ||
                            widget.onEvolve == null ||
                            !hasNextStage)
                        ? null
                        : _handleEvolveClick,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      widget.isSubmitting
                          ? l10n.spiritEvolving
                          : l10n.spiritEvolveNow,
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
            color: active
                ? primary
                : theme.colorScheme.surfaceVariant.withOpacity(0.18),
          ),
          child: Icon(
            done ? Icons.check : Icons.circle_outlined,
            size: 16,
            color: active
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.6),
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

class _EvolutionOverlayStateful extends StatefulWidget {
  const _EvolutionOverlayStateful({required this.primary, super.key});

  final Color primary;

  @override
  State<_EvolutionOverlayStateful> createState() =>
      _EvolutionOverlayStatefulState();
}

class _EvolutionOverlayStatefulState extends State<_EvolutionOverlayStateful>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.primary.withOpacity(0.20),
                      widget.primary.withOpacity(0.06),
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
                      color: widget.primary,
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
                      color: widget.primary.withOpacity(0.12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.spa_rounded,
                        size: 88,
                        color: widget.primary,
                      ),
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

class _EvolutionOverlay extends StatelessWidget {
  const _EvolutionOverlay({required this.primary, super.key});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return _EvolutionOverlayStateful(primary: primary);
  }
}
