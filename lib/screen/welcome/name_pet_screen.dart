import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

import '../../core/constants/app_assets.dart';
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
      begin: const Offset(0.18, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectIfPetExists();
    });
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final gameState = context.read<GameStateProvider>();
    final name = _nameController.text.trim();
    final success = await gameState.createStarterPet(name);

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const primary = AuthStyle.forest;
    const onPrimary = AuthStyle.cream;
    final cardColor = AuthStyle.cream.withValues(alpha: 0.92);
    final mutedForeground = AuthStyle.forest.withValues(alpha: 0.78);
    const accent = AuthStyle.rust;

    if (_isCheckingPet) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthGardenScaffold(
        child: SafeArea(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.72),
                                  border: Border.all(
                                    color: AuthStyle.gold.withValues(
                                      alpha: 0.42,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: AppIcon(
                                  Icons.local_florist_rounded,
                                  size: 46,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                l10n.namePetTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AuthStyle.forestDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.namePetDescription,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: mutedForeground,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nameController,
                                enabled: !_isSaving,
                                cursorColor: Colors.black,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _complete(),
                                validator: _validateName,
                                decoration: InputDecoration(
                                  hintText: l10n.namePetHint,
                                  hintStyle: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      AppAssets.authRegisterSeed,
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.78,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD8CDAE),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD8CDAE),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: const BorderSide(
                                      color: AuthStyle.gold,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _complete,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          l10n.namePetComplete,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
