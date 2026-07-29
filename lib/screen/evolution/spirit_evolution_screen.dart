import 'dart:async';
import 'dart:math' as math;

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
    this.evolutionOptions = const <PetEvolutionOptionResponse>[],
    this.evolutionPreviews = const <PetEvolutionPreviewResponse>[],
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
  final List<PetEvolutionOptionResponse> evolutionOptions;
  final List<PetEvolutionPreviewResponse> evolutionPreviews;
  final bool isLoading;
  final bool isSubmitting;
  final Future<bool> Function()? onEvolve;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onEvolved;

  @override
  State<SpiritEvolutionScreen> createState() => _SpiritEvolutionScreenState();
}

class _SpiritEvolutionScreenState extends State<SpiritEvolutionScreen>
    with SingleTickerProviderStateMixin {
  late bool _isEvolved;
  bool _isAnimating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ScrollController _animScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isEvolved = widget.initialIsEvolved;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _animScrollController.dispose();
    super.dispose();
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

    // Required level from options (next tier above current)
    final currentLvl = widget.overview?.level ?? widget.level;
    final nextRequiredLevel = widget.evolutionOptions.isNotEmpty
        ? widget.evolutionOptions
              .map((o) => o.requiredLevel)
              .where((lvl) => lvl > currentLvl)
              .fold<int?>(
                null,
                (prev, lvl) => prev == null || lvl < prev ? lvl : prev,
              )
        : null;
    
    // Ưu tiên dùng nextEvolutionLevel từ API /api/pet/me
    final conditionLevelTarget = (widget.overview != null && widget.overview!.nextEvolutionLevel > 0)
        ? widget.overview!.nextEvolutionLevel
        : nextRequiredLevel;

    return SingleChildScrollView(
      key: const ValueKey('evolution'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Giai Đoạn Tiến Hóa ──────────────────────────────────
          _SectionLabel(label: l10n.spiritEvolutionStages),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline row
                if (widget.stages.isEmpty)
                  Center(
                    child: _StageNode(
                      title: stageDisplayName.isNotEmpty
                          ? stageDisplayName
                          : l10n.spiritStageSeed,
                      imageUrl: currentStage?.stateUrl,
                      isDone: true,
                      isActive: true,
                      pulseAnimation: _pulseAnimation,
                    ),
                  )
                else
                  Row(
                    children: _buildTimelineItems(
                      context,
                      primary,
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 10),
                // Bottom: info + ready badge
                Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      size: 14,
                      color: primary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
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
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (readyForEvolution)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 12,
                              color: primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.spiritReady,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Animations of current stage
                if (currentStage != null && currentStage.animations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),
                  Text(
                    'Trạng thái của pet ở dạng hiện tại:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: mutedFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 85,
                    child: RawScrollbar(
                      controller: _animScrollController,
                      thumbColor: primary.withOpacity(0.5),
                      radius: const Radius.circular(8),
                      thickness: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          controller: _animScrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: currentStage.animations.map((anim) {
                              final isNetwork = anim.animationUrl.startsWith('http');
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: isNetwork
                                            ? Image.network(
                                                anim.animationUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                                              )
                                            : Image.asset(
                                                anim.animationUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      anim.typeAnimation,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 9,
                                        color: mutedFg,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Lịch Sử Tiến Hóa ────────────────────────────────────
          _SectionLabel(label: l10n.spiritEvolutionHistory),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.16)),
            ),
            child: widget.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.history.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: mutedFg.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chưa có lịch sử tiến hóa.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: mutedFg,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: widget.history.map((item) {
                      final dt = DateTime.tryParse(item.evolvedAt);
                      final subtitle = dt != null
                          ? '${dt.day}/${dt.month}/${dt.year}  •  Cấp ${item.level}'
                          : item.evolvedAt.isNotEmpty
                          ? item.evolvedAt
                          : 'Cấp ${item.level}';
                      return _HistoryRow(
                        icon: Icons.auto_awesome,
                        title: item.stageName,
                        subtitle: subtitle,
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 14),

          // ── Điều Kiện Tiến Hóa ──────────────────────────────────
          if (!_isEvolved || hasNextStage) ...[
            _SectionLabel(label: l10n.spiritEvolutionConditions),
            const SizedBox(height: 8),
            if (conditionLevelTarget != null) ...[
              _ConditionCard(
                text: 'Đạt Cấp $conditionLevelTarget',
                value: '$currentLvl/$conditionLevelTarget',
                ok: currentLvl >= conditionLevelTarget,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            // Evolve button
            _buildEvolveButton(
              context,
              l10n,
              primary,
              canEvolve: canEvolve,
              hasNextStage: hasNextStage,
            ),
          ] else ...[
            // Max evolution card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(0.12),
                    primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.stars_rounded, color: primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.spiritMaxEvolution,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.evolutionPreviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionLabel(label: 'Xem trước các dạng tiến hóa'),
            const SizedBox(height: 8),
            _PreviewSection(previews: widget.evolutionPreviews),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineItems(BuildContext context, Color primary) {
    final theme = Theme.of(context);
    final result = <Widget>[];
    for (int i = 0; i < widget.stages.length; i++) {
      final stage = widget.stages[i];
      final isDone = stage.isUnlocked || _isEvolved;
      final isActive =
          stage.isCurrent ||
          (i == 0 && !widget.stages.any((item) => item.isCurrent));

      result.add(
        Expanded(
          child: _StageNode(
            title: stage.stageName,
            imageUrl: stage.stateUrl,
            isDone: isDone,
            isActive: isActive,
            pulseAnimation: _pulseAnimation,
          ),
        ),
      );

      if (i < widget.stages.length - 1) {
        final nextDone = widget.stages[i + 1].isUnlocked || _isEvolved;
        result.add(
          SizedBox(
            width: 24,
            height: 2,
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: isDone && nextDone
                    ? primary.withOpacity(0.7)
                    : theme.colorScheme.outlineVariant.withOpacity(0.4),
                isCompleted: isDone && nextDone,
              ),
            ),
          ),
        );
      }
    }
    return result;
  }

  Widget _buildEvolveButton(
    BuildContext context,
    AppLocalizations l10n,
    Color primary, {
    required bool canEvolve,
    required bool hasNextStage,
  }) {
    final theme = Theme.of(context);
    final isEnabled = !widget.isSubmitting &&
        canEvolve &&
        hasNextStage &&
        widget.onEvolve != null;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isEnabled
              ? LinearGradient(
                  colors: [primary, primary.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isEnabled ? null : theme.colorScheme.surfaceVariant,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? _handleEvolveClick : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isSubmitting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: isEnabled
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isSubmitting
                        ? l10n.spiritEvolving
                        : l10n.spiritEvolveNow,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isEnabled
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
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

// ─────────────────────────────────────────────────────────
//  Section label
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Stage Node (circle with pulse)
// ─────────────────────────────────────────────────────────
class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.title,
    this.imageUrl,
    required this.isDone,
    required this.isActive,
    required this.pulseAnimation,
  });

  final String title;
  final String? imageUrl;
  final bool isDone;
  final bool isActive;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            final isNetworkImage = imageUrl?.startsWith('http') ?? false;

            return Transform.scale(
              scale: isActive ? pulseAnimation.value : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isActive)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withOpacity(0.15),
                      ),
                    ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? primary
                          : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      border: Border.all(
                        color: isActive
                            ? primary
                            : theme.colorScheme.outlineVariant.withOpacity(0.5),
                        width: isActive ? 2.0 : 1.0,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: primary.withOpacity(0.35),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? (isNetworkImage
                              ? Image.network(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackIcon(theme, isDone),
                                )
                              : Image.asset(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackIcon(theme, isDone),
                                ))
                          : _buildFallbackIcon(theme, isDone),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.55),
            height: 1.3,
          ),
        ),
      ],
    );
  }
  Widget _buildFallbackIcon(ThemeData theme, bool isDone) {
    return Icon(
      isDone ? Icons.check_rounded : Icons.circle_outlined,
      size: 18,
      color: isDone
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface.withOpacity(0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Dashed / solid connector between stage nodes
// ─────────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    required this.isCompleted,
  });

  final Color color;
  final bool isCompleted;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (isCompleted) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset(math.min(startX + dashWidth, size.width), size.height / 2),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color || old.isCompleted != isCompleted;
}

// ─────────────────────────────────────────────────────────
//  History Row
// ─────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
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

// ─────────────────────────────────────────────────────────
//  Condition Card
// ─────────────────────────────────────────────────────────
class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.text,
    required this.value,
    required this.ok,
  });

  final String text;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ok ? primary.withOpacity(0.06) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ok
              ? primary.withOpacity(0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              key: ValueKey(ok),
              color: ok
                  ? primary
                  : theme.colorScheme.onSurface.withOpacity(0.45),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ok
                  ? primary.withOpacity(0.12)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: ok
                    ? primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Evolution Overlay (animation khi nhấn tiến hóa)
// ─────────────────────────────────────────────────────────
class _EvolutionOverlayStateful extends StatefulWidget {
  const _EvolutionOverlayStateful({required this.primary, super.key});

  final Color primary;

  @override
  State<_EvolutionOverlayStateful> createState() =>
      _EvolutionOverlayStatefulState();
}

class _EvolutionOverlayStatefulState extends State<_EvolutionOverlayStateful>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Container(
            color: theme.colorScheme.background.withOpacity(0.95),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          widget.primary
                              .withOpacity(0.25 * _controller.value),
                          widget.primary
                              .withOpacity(0.08 * _controller.value),
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
                      const SizedBox(height: 32),
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primary.withOpacity(0.12),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primary.withOpacity(0.4),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.spa_rounded,
                              size: 80,
                              color: widget.primary,
                            ),
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
      },
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

// ─────────────────────────────────────────────────────────
//  Preview Section
// ─────────────────────────────────────────────────────────
class _PreviewSection extends StatefulWidget {
  const _PreviewSection({required this.previews});

  final List<PetEvolutionPreviewResponse> previews;

  @override
  State<_PreviewSection> createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<_PreviewSection> {
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _getController(String key) {
    if (!_scrollControllers.containsKey(key)) {
      _scrollControllers[key] = ScrollController();
    }
    return _scrollControllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return Column(
      children: widget.previews.map((pet) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header pet name
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.pets, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pet.petName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              // Stages
              ...pet.stages.map((stage) {
                final isNetworkImage = stage.stageImage.startsWith('http');
                final scrollKey = '${pet.petId}_${stage.stageNo}';
                
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: primary.withOpacity(0.3)),
                            ),
                            child: ClipOval(
                              child: stage.stageImage.isNotEmpty
                                  ? (isNetworkImage
                                      ? Image.network(
                                          stage.stageImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 24, color: mutedFg),
                                        )
                                      : Image.asset(
                                          stage.stageImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 24, color: mutedFg),
                                        ))
                                  : Icon(Icons.help_outline, color: mutedFg),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage.stageName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cấp độ yêu cầu: ${stage.requiredLevel}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: mutedFg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (stage.animations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Hoạt ảnh:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: mutedFg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 85,
                          child: RawScrollbar(
                            controller: _getController(scrollKey),
                            thumbColor: primary.withOpacity(0.3),
                            radius: const Radius.circular(8),
                            thickness: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SingleChildScrollView(
                                controller: _getController(scrollKey),
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: stage.animations.map((anim) {
                                    final animIsNetwork = anim.animationUrl.startsWith('http');
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: animIsNetwork
                                                  ? Image.network(
                                                      anim.animationUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16),
                                                    )
                                                  : Image.asset(
                                                      anim.animationUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 16),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            anim.typeAnimation,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontSize: 9,
                                              color: mutedFg,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
