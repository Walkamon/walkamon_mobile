import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _EvolutionPath {
  const _EvolutionPath({
    required this.name,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  final String name;
  final String description;
  final IconData icon;
  final Color accentColor;
}

class _SeedScreenState extends State<SeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.18, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/name-pet');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final accent = isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIntroCard(
                        theme: theme,
                        l10n: l10n,
                        primary: primary,
                        accent: accent,
                        mutedForeground: mutedForeground,
                      ),
                      const SizedBox(height: 20),
                      _buildEvolutionCard(theme, l10n, mutedForeground),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            l10n.seedContinue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard({
    required ThemeData theme,
    required AppLocalizations l10n,
    required Color primary,
    required Color accent,
    required Color mutedForeground,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
              border: Border.all(
                color: primary.withValues(alpha: 0.22),
                width: 1.5,
              ),
            ),
            child: Icon(Icons.local_florist_rounded, size: 46, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.seedTitleScreen,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.seedDescriptionScreen,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mutedForeground,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionCard(
    ThemeData theme,
    AppLocalizations l10n,
    Color mutedForeground,
  ) {
    final evolutionPaths = [
      _EvolutionPath(
        name: l10n.seedPath1Name,
        description: l10n.seedPath1Description,
        icon: Icons.wb_sunny_outlined,
        accentColor: const Color(0xFFF59E0B),
      ),
      _EvolutionPath(
        name: l10n.seedPath2Name,
        description: l10n.seedPath2Description,
        icon: Icons.nightlight_round,
        accentColor: const Color(0xFF6366F1),
      ),
      _EvolutionPath(
        name: l10n.seedPath3Name,
        description: l10n.seedPath3Description,
        icon: Icons.local_florist_outlined,
        accentColor: const Color(0xFF22C55E),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.seedEvolutionTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.seedEvolutionDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mutedForeground,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          ...evolutionPaths.map(
            (path) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: path.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(path.icon, color: path.accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            path.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedForeground,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
