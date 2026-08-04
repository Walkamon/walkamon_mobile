import 'dart:async';

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
      final gameState = context.read<GameStateProvider>();
      final petRepository = gameState.petRepository;

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

      await Future.wait([
        gameState.fetchPetStatus(),
        gameState.fetchPetVisual(),
      ]);
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
                                    flex: 3,
                                    child: Center(
                                      child: Container(
                                        width: 250,
                                        height: 250,
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
                                                height: 148,
                                              ),
                                              const SizedBox(height: 6),
                                              GameButtonLabel(
                                                spiritName,
                                                fontSize: 16,
                                                color: AppColors.woodDeep,
                                                outlineColor:
                                                    AppColors.authCard,
                                                outlineWidth: 3.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        10,
                                        18,
                                        10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCard.withValues(
                                                alpha: 0.96,
                                              )
                                            : AppColors.authCard.withValues(
                                                alpha: 0.96,
                                              ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.wood,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.woodDeep
                                                .withValues(alpha: 0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
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
                                                          child: Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: GameButtonLabel(
                                                              spiritName,
                                                              fontSize: 19,
                                                              color: AppColors
                                                                  .woodDeep,
                                                              outlineColor:
                                                                  AppColors
                                                                      .creamLight,
                                                              outlineWidth: 3,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .leafLight
                                                                .withValues(
                                                                  alpha: 0.62,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .wood
                                                                  .withValues(
                                                                    alpha: 0.65,
                                                                  ),
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
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.darkMuted
                                                  : AppColors.authCard
                                                        .withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.wood,
                                                width: 1.5,
                                              ),
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
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 0,
                                                  ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                layoutBuilder:
                                                    (
                                                      currentChild,
                                                      previousChildren,
                                                    ) => Stack(
                                                      alignment:
                                                          Alignment.topCenter,
                                                      children: [
                                                        ...previousChildren,
                                                        if (currentChild !=
                                                            null)
                                                          currentChild,
                                                      ],
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
                                                        stages:
                                                            _evolutionStages,
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
                                                              showLoading:
                                                                  false,
                                                            ),
                                                        onEvolved: () {
                                                          if (!mounted) return;
                                                          setState(
                                                            () => _isEvolved =
                                                                true,
                                                          );
                                                        },
                                                      ),
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
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('stats'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  title: 'EXP',
                  current: exp,
                  maximum: maxExp,
                  color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
                ),
                const SizedBox(height: 7),
                _StatRow(
                  title: l10n.lifeForce,
                  current: health,
                  maximum: maxLifeForce,
                  color: isDark ? AppColors.darkLife : AppColors.lightLife,
                ),
                const SizedBox(height: 7),
                _StatRow(
                  title: l10n.bonding,
                  current: bonding,
                  maximum: maxBond,
                  color: isDark ? AppColors.darkBond : AppColors.lightBond,
                ),
                const SizedBox(height: 7),
                _StatRow(
                  title: l10n.energy,
                  current: energy,
                  maximum: maxEnergy,
                  color: isDark ? AppColors.darkDew : AppColors.lightDew,
                ),
              ],
            ),
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
    return Material(
      color: active ? AppColors.buttonGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? AppColors.woodDeep : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: active
                ? GameButtonLabel(
                    label,
                    fontSize: 13,
                    color: AppColors.buttonText,
                    outlineColor: AppColors.woodDeep,
                    outlineWidth: 2.5,
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.woodDeep,
                    ),
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
        color: AppColors.creamLight.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.wood.withValues(alpha: 0.65),
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.inkBrown,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.title,
    required this.current,
    required this.maximum,
    required this.color,
    super.key,
  });

  final String title;
  final int current;
  final int maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeMaximum = maximum <= 0 ? 1 : maximum;
    final progress = (current / safeMaximum).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.inkBrown,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 12,
                  child: Container(
                    height: 17,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.creamLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.woodDeep, width: 1.5),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: animatedProgress,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  right: 12,
                  child: Center(
                    child: Text(
                      '$current/$maximum',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkDark,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: -2,
                  child: CustomPaint(
                    size: Size(29, 29),
                    painter: _ProgressLeafPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressLeafPainter extends CustomPainter {
  const _ProgressLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Path()
      ..moveTo(size.width * 0.13, size.height * 0.76)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.20,
        size.width * 0.68,
        size.height * 0.02,
        size.width * 0.88,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.98,
        size.height * 0.48,
        size.width * 0.70,
        size.height * 0.91,
        size.width * 0.13,
        size.height * 0.76,
      )
      ..close();

    canvas.drawPath(leaf, Paint()..color = AppColors.leafBright);
    canvas.drawPath(
      leaf,
      Paint()
        ..color = AppColors.oliveDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final vein = Paint()
      ..color = AppColors.oliveDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.86),
      Offset(size.width * 0.78, size.height * 0.20),
      vein,
    );
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.54),
      Offset(size.width * 0.42, size.height * 0.27),
      vein,
    );
    canvas.drawLine(
      Offset(size.width * 0.57, size.height * 0.43),
      Offset(size.width * 0.76, size.height * 0.48),
      vein,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final enabled = onPressed != null;

    return Material(
      color: enabled
          ? AppColors.buttonGreen
          : AppColors.buttonSecondary.withValues(alpha: 0.75),
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.woodDeep, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon,
                size: 19,
                color: enabled ? AppColors.buttonText : AppColors.outlineBrown,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: GameButtonLabel(
                  label,
                  fontSize: 12,
                  color: enabled
                      ? AppColors.buttonText
                      : AppColors.outlineBrown,
                  outlineColor: enabled
                      ? AppColors.woodDeep
                      : AppColors.authCard,
                  outlineWidth: 2.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
