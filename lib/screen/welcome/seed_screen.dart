import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../auth/widgets/auth_style.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _EvolutionPath {
  const _EvolutionPath({
    required this.name,
    required this.description,
    required this.affinityCode,
  });

  final String name;
  final String description;
  final String affinityCode;
}

class _SeedScreenState extends State<SeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _isCheckingPet = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfPetExists());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _redirectIfPetExists() async {
    final gameState = context.read<GameStateProvider>();

    // The backend story-status is authoritative for each account. A story
    // completed in this session may proceed to seed/name-pet, but it is not
    // marked seen until starter-pet creation succeeds.
    final hasSeenStory = await gameState.loadHasSeenStory();
    if (!mounted) return;
    if (!hasSeenStory && !gameState.hasCompletedStoryThisSession) {
      Navigator.pushReplacementNamed(context, '/story');
      return;
    }

    final hasPet = await gameState.preparePetForHome();
    if (!mounted) return;
    if (hasPet) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    setState(() => _isCheckingPet = false);
  }

  Future<void> _continue() async {
    final hasPet = await context.read<GameStateProvider>().preparePetForHome();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, hasPet ? '/home' : '/name-pet');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthGardenScaffold(
        backgroundAsset: AppAssets.onboardingSeed,
        child: SafeArea(
          child: _isCheckingPet
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.oliveDeep),
                )
              : FadeTransition(
                  opacity: _opacity,
                  child: SlideTransition(
                    position: _slide,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 42,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildIntroCard(l10n),
                                    const SizedBox(height: 12),
                                    _buildEvolutionPanel(l10n),
                                    const SizedBox(height: 14),
                                    _SeedContinueButton(
                                      label: l10n.seedContinue,
                                      onPressed: _continue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.wood, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            padding: const EdgeInsets.all(4),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.creamLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.wood, width: 1.8),
            ),
            child: const PetRuntimePreview(
              affinityCode: 'sprout',
              stageNo: 0,
              animationType: 'idle',
              compact: true,
              height: 122,
            ),
          ),
          const SizedBox(height: 12),
          GameButtonLabel(
            l10n.seedTitleScreen,
            fontSize: 23,
            color: AppColors.woodDeep,
            outlineColor: AppColors.creamLight,
            outlineWidth: 3.5,
          ),
          const SizedBox(height: 9),
          Text(
            l10n.seedDescriptionScreen,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.inkBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionPanel(AppLocalizations l10n) {
    final paths = [
      _EvolutionPath(
        name: l10n.seedPath1Name,
        description: l10n.seedPath1Description,
        affinityCode: 'dawn',
      ),
      _EvolutionPath(
        name: l10n.seedPath2Name,
        description: l10n.seedPath2Description,
        affinityCode: 'moonlight',
      ),
      _EvolutionPath(
        name: l10n.seedPath3Name,
        description: l10n.seedPath3Description,
        affinityCode: 'warm_sun',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.leafLight.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.oliveDeep, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
            child: Column(
              children: [
                GameButtonLabel(
                  l10n.seedEvolutionTitle,
                  fontSize: 18,
                  color: AppColors.woodDeep,
                  outlineColor: AppColors.leafLight,
                  outlineWidth: 3,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.seedEvolutionDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkBrown,
                  ),
                ),
              ],
            ),
          ),
          ...paths.map(_buildEvolutionPathCard),
        ],
      ),
    );
  }

  Widget _buildEvolutionPathCard(_EvolutionPath path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.authCard.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.wood, width: 1.35),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.creamLight,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.wood, width: 1.2),
            ),
            child: PetRuntimePreview(
              affinityCode: path.affinityCode,
              stageNo: 1,
              animationType: 'idle',
              compact: true,
              height: 74,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.woodDeep,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  path.description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.outlineBrown,
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

class _SeedContinueButton extends StatelessWidget {
  const _SeedContinueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.buttonGreen,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.woodDeep, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SeedButtonLeafPainter()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 15,
                ),
                child: GameButtonLabel(
                  label,
                  fontSize: 17,
                  color: AppColors.buttonText,
                  outlineColor: AppColors.woodDeep,
                  outlineWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeedButtonLeafPainter extends CustomPainter {
  const _SeedButtonLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 110) return;
    final fill = Paint()..color = AppColors.oliveDeep;
    final edge = Paint()
      ..color = AppColors.woodDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    void drawLeaf(Offset center, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: 16, height: 8);
      canvas.drawOval(rect, fill);
      canvas.drawOval(rect, edge);
      canvas.restore();
    }

    final y = size.height / 2;
    drawLeaf(Offset(9, y - 5), -0.55);
    drawLeaf(Offset(9, y + 5), 0.55);
    drawLeaf(Offset(size.width - 9, y - 5), 0.55);
    drawLeaf(Offset(size.width - 9, y + 5), -0.55);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
