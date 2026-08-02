import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/pet_evolution_models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../evolution/spirit_evolution_screen.dart';
import '../../widgets/pet_runtime/pet_runtime_preview.dart';

class SpiritDetailScreen extends StatefulWidget {
  const SpiritDetailScreen({super.key});

  @override
  State<SpiritDetailScreen> createState() => _SpiritDetailScreenState();
}

class _SpiritDetailScreenState extends State<SpiritDetailScreen> {
  String _activeTab = 'stats';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isEvolved = false;
  String? _petAnimationOverride;
  Timer? _petAnimationTimer;
  PetOverviewResponse? _petOverview;
  List<PetEvolutionStageResponse> _evolutionStages =
      <PetEvolutionStageResponse>[];
  List<PetEvolutionHistoryResponse> _evolutionHistory =
      <PetEvolutionHistoryResponse>[];
  List<PetEvolutionOptionResponse> _evolutionOptions =
      <PetEvolutionOptionResponse>[];
  List<PetEvolutionPreviewResponse> _evolutionPreviews =
      <PetEvolutionPreviewResponse>[];
  PetCurrentAnimationResponse? _currentAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPetData();
    });
  }

  @override
  void dispose() {
    _petAnimationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPetData({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final gameState = context.read<GameStateProvider>();
      final petRepository = gameState.petRepository;

      final overview = await petRepository.getPetOverview();
      final stages = await petRepository.getEvolutionStages();
      final history = await petRepository.getEvolutionHistory();
      final animation = await petRepository.getCurrentAnimation();
      List<PetEvolutionOptionResponse> options = <PetEvolutionOptionResponse>[];
      try {
        options = await petRepository.getEvolutionOptions();
      } catch (_) {}

      List<PetEvolutionPreviewResponse> previews =
          <PetEvolutionPreviewResponse>[];
      try {
        previews = await petRepository.getEvolutionPreviews();
      } catch (_) {}

      if (!mounted) return;

      final sortedStages = [...stages]
        ..sort((a, b) => a.stageNo.compareTo(b.stageNo));
      final sortedHistory = [...history]
        ..sort((a, b) {
          final aTime = DateTime.tryParse(a.evolvedAt);
          final bTime = DateTime.tryParse(b.evolvedAt);
          if (aTime == null || bTime == null) {
            return b.stageNo.compareTo(a.stageNo);
          }
          return bTime.compareTo(aTime);
        });

      setState(() {
        _petOverview = overview;
        _evolutionStages = sortedStages;
        _evolutionHistory = sortedHistory;
        _evolutionOptions = options;
        _evolutionPreviews = previews;
        _currentAnimation = animation;
        _isEvolved = overview.stageNo > 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _handleEvolutionSubmit([String? petId]) async {
    if (_isSubmitting) return false;

    setState(() => _isSubmitting = true);

    try {
      final petRepository = context.read<GameStateProvider>().petRepository;

      bool success = false;
      if (petId != null) {
        success = await petRepository.evolveToFamily(petId);
      } else {
        success = await petRepository.evolveToNextStage();
      }

      if (!mounted) return false;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể tiến hóa lúc này.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return false;
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleAction(
    Future<bool> Function() action,
    String successMessage,
    String successAnimation,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final success = await action();

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (success) _petAnimationOverride = successAnimation;
    });

    if (success) {
      _petAnimationTimer?.cancel();
      _petAnimationTimer = Timer(
        Duration(milliseconds: successAnimation == 'feed_eat' ? 900 : 600),
        () {
          if (mounted) setState(() => _petAnimationOverride = null);
        },
      );
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
        final maxBond = (_petOverview?.maxBond ?? 100) > 0
            ? (_petOverview?.maxBond ?? 100)
            : 100;
        final bonding = (_petOverview?.currentBond ?? gameState.bondingLevel)
            .clamp(0, maxBond);
        final maxEnergy = (_petOverview?.maxEnergy ?? 100) > 0
            ? (_petOverview?.maxEnergy ?? 100)
            : 100;
        final energy = (_petOverview?.currentEnergy ?? gameState.spiritEnergy)
            .clamp(0, maxEnergy);
        final maxLifeForce = (_petOverview?.maxLifeForce ?? 100) > 0
            ? (_petOverview?.maxLifeForce ?? 100)
            : 100;
        final health =
            (_petOverview?.currentLifeForce ?? gameState.spiritHealth).clamp(
              0,
              maxLifeForce,
            );
        final level = _petOverview?.level ?? gameState.spiritLevel;
        final maxExp = (_petOverview?.maxExp ?? 100) > 0
            ? (_petOverview?.maxExp ?? 100)
            : 100;
        final exp = (_petOverview?.currentExp ?? gameState.spiritExp).clamp(
          0,
          maxExp,
        );
        final spiritName = _petOverview?.nickname ?? gameState.spiritName;
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                      child: Row(
                        children: [
                          GameBackButton(
                            semanticLabel: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: GameButtonLabel(
                                l10n.spiritDetailTitle(spiritName),
                                fontSize: 17,
                                color: AppColors.woodDeep,
                                outlineColor: AppColors.authCard,
                                outlineWidth: 4,
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
                                              PetRuntimePreview(
                                                assetReference:
                                                    _currentAnimation
                                                        ?.animationUrl,
                                                affinityCode:
                                                    _petOverview
                                                        ?.affinityCode ??
                                                    gameState.affinityCode,
                                                stageNo:
                                                    _petOverview?.stageNo ??
                                                    gameState.petStageNo,
                                                animationType:
                                                    _petAnimationOverride ??
                                                    _currentAnimation
                                                        ?.animationType ??
                                                    _petOverview
                                                        ?.animationType ??
                                                    gameState.animationType,
                                                compact: true,
                                                height: 112,
                                              ),
                                              const SizedBox(height: 6),
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
                                                      maxEnergy: maxEnergy,
                                                      health: health,
                                                      maxLifeForce:
                                                          maxLifeForce,
                                                      maxBond: maxBond,
                                                      exp: exp,
                                                      maxExp: maxExp,
                                                      usableItems: usableItems,
                                                      isDark: isDark,
                                                    )
                                                  : SpiritEvolutionScreen(
                                                      key: ValueKey(
                                                        'evolution',
                                                      ),
                                                      level: level,
                                                      bonding: bonding,
                                                      initialIsEvolved:
                                                          isEvolved,
                                                      overview: _petOverview,
                                                      stages: _evolutionStages,
                                                      history:
                                                          _evolutionHistory,
                                                      evolutionOptions:
                                                          _evolutionOptions,
                                                      evolutionPreviews:
                                                          _evolutionPreviews,
                                                      isLoading: _isLoading,
                                                      isSubmitting:
                                                          _isSubmitting,
                                                      onEvolve:
                                                          _handleEvolutionSubmit,
                                                      onRefresh: () =>
                                                          _loadPetData(
                                                            showLoading: false,
                                                          ),
                                                      onEvolved: () {
                                                        if (!mounted) return;
                                                        setState(
                                                          () =>
                                                              _isEvolved = true,
                                                        );
                                                      },
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
    required int maxEnergy,
    required int health,
    required int maxLifeForce,
    required int maxBond,
    required int exp,
    required int maxExp,
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
            title: 'EXP',
            progress: exp / maxExp,
            color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          ),
          const SizedBox(height: 10),
          _StatRow(
            title: l10n.lifeForce,
            progress: health / maxLifeForce,
            color: isDark ? AppColors.darkLife : AppColors.lightLife,
          ),
          const SizedBox(height: 10),
          _StatRow(
            title: l10n.bonding,
            progress: bonding / maxBond,
            color: isDark ? AppColors.darkBond : AppColors.lightBond,
          ),
          const SizedBox(height: 10),
          _StatRow(
            title: l10n.energy,
            progress: energy / maxEnergy,
            color: isDark ? AppColors.darkDew : AppColors.lightDew,
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
                          child: AppIcon(
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
                          'excited',
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
                          'feed_eat',
                        ),
                ),
              ),
            ],
          ),
        ],
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
    required this.progress,
    required this.color,
    super.key,
  });

  final String title;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressPercent = (progress.clamp(0.0, 1.0) * 100).round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 11,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: animatedProgress,
                  child: SizedBox.expand(child: ColoredBox(color: color)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 42,
          child: Text(
            '$progressPercent%',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
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
      icon: AppIcon(
        icon,
        size: 18,
        color: onPressed == null ? theme.disabledColor : null,
        tintAsset: onPressed == null,
      ),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
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
