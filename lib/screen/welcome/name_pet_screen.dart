import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';

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

    final currentName = context.read<GameStateProvider>().user?.name;
    if (currentName != null && currentName.isNotEmpty) {
      _nameController.text = currentName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Tên không được để trống.';
    if (name.length < 2) return 'Tên phải có ít nhất 2 ký tự.';
    return null;
  }

  Future<void> _complete() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final gameState = context.read<GameStateProvider>();
    final currentUser = gameState.user;
    final name = _nameController.text.trim();

    if (currentUser != null) {
      gameState.setUser(
        GameUser(
          id: currentUser.id,
          email: currentUser.email,
          name: name,
          level: currentUser.level,
          steps: currentUser.steps,
          coins: currentUser.coins,
          joinDate: currentUser.joinDate,
          bio: currentUser.bio,
          gender: currentUser.gender,
          dob: currentUser.dob,
          avatarUrl: currentUser.avatarUrl,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final cardColor = theme.colorScheme.surface;
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                              color: theme.colorScheme.outline.withValues(alpha: 0.18),
                            ),
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
                                child: Icon(
                                  Icons.local_florist_rounded,
                                  size: 46,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Đặt tên cho Lumina',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Hãy chọn một cái tên thật ý nghĩa cho người bạn đồng hành của mình.',
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
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _complete(),
                                validator: _validateName,
                                decoration: InputDecoration(
                                  hintText: 'Nhập tên tinh linh...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
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
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Hoàn tất',
                                          style: TextStyle(
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
    );
  }
}
