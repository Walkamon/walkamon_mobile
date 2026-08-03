import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../auth/widgets/auth_style.dart';

class NamePetScreen extends StatefulWidget {
  const NamePetScreen({super.key});

  @override
  State<NamePetScreen> createState() => _NamePetScreenState();
}

class _NamePetScreenState extends State<NamePetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  bool _isCheckingPet = true;
  bool _isSaving = false;

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
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context);
    final name = value?.trim() ?? '';
    if (name.isEmpty) return l10n.registerNameRequired;
    if (name.length < 2) return l10n.registerNameMinLength;
    return null;
  }

  Future<void> _redirectIfPetExists() async {
    final hasPet = await context.read<GameStateProvider>().fetchPetName();
    if (!mounted) return;
    if (hasPet) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }
    setState(() => _isCheckingPet = false);
  }

  Future<void> _complete() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final gameState = context.read<GameStateProvider>();
    final success = await gameState.createStarterPet(
      _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).namePetCreateFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthGardenScaffold(
        backgroundAsset: AppAssets.onboardingNamePet,
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
                        final petSize = (constraints.maxHeight * 0.24)
                            .clamp(160.0, 240.0)
                            .toDouble();
                        final cardToPetGap = (constraints.maxHeight * 0.025)
                            .clamp(12.0, 24.0)
                            .toDouble();

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
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildNameCard(l10n),
                                      SizedBox(height: cardToPetGap),
                                      PetRuntimePreview(
                                        affinityCode: 'sprout',
                                        stageNo: 0,
                                        animationType: 'idle',
                                        compact: true,
                                        height: petSize,
                                      ),
                                    ],
                                  ),
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

  Widget _buildNameCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          GameButtonLabel(
            l10n.namePetTitle,
            fontSize: 23,
            color: AppColors.woodDeep,
            outlineColor: AppColors.creamLight,
            outlineWidth: 3.5,
          ),
          const SizedBox(height: 9),
          Text(
            l10n.namePetDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: AppColors.inkBrown,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _nameController,
            enabled: !_isSaving,
            cursorColor: AppColors.woodDeep,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _complete(),
            validator: _validateName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.inkDark,
            ),
            decoration: InputDecoration(
              hintText: l10n.namePetHint,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.outlineBrown.withValues(alpha: 0.75),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(AppAssets.iconEdit, width: 27, height: 27),
              ),
              filled: true,
              fillColor: AppColors.creamLight.withValues(alpha: 0.82),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: _inputBorder(AppColors.wood),
              enabledBorder: _inputBorder(AppColors.wood),
              focusedBorder: _inputBorder(AppColors.woodDeep, width: 2),
              errorBorder: _inputBorder(AppColors.danger, width: 1.7),
              focusedErrorBorder: _inputBorder(AppColors.danger, width: 2),
              errorStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NamePetActionButton(
            label: l10n.namePetComplete,
            loading: _isSaving,
            onPressed: _complete,
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1.4}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _NamePetActionButton extends StatelessWidget {
  const _NamePetActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: loading
          ? AppColors.buttonGreen.withValues(alpha: 0.68)
          : AppColors.buttonGreen,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: double.infinity,
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
                  child: CustomPaint(painter: _NamePetButtonLeafPainter()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 15,
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.authCard,
                        ),
                      )
                    : GameButtonLabel(
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

class _NamePetButtonLeafPainter extends CustomPainter {
  const _NamePetButtonLeafPainter();

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
