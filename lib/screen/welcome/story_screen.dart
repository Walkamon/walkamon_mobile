import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../auth/widgets/auth_style.dart';

class StorySlide {
  const StorySlide({required this.image, required this.text});

  final String image;
  final String text;
}

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    final slides = _storySlides(AppLocalizations.of(context));
    if (_currentPage < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      await _goToPetOnboarding();
    }
  }

  Future<void> _skipStory() async {
    await _goToPetOnboarding();
  }

  Future<void> _goToPetOnboarding() async {
    final hasPet = await context.read<GameStateProvider>().preparePetForHome();
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, hasPet ? '/home' : '/seed');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final storySlides = _storySlides(l10n);
    final currentSlide = storySlides[_currentPage];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: storySlides.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final slide = storySlides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AuthStyle.cream),
                  Image.asset(
                    slide.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0x120F2819),
                          const Color(0x00FFF7E3),
                          const Color(0x66365525),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1}/${storySlides.length}',
                    style: TextStyle(
                      color: AuthStyle.forestDark,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.white70, blurRadius: 10),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _skipStory,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      backgroundColor: AuthStyle.cream.withValues(alpha: 0.86),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      l10n.storySkip,
                      style: TextStyle(
                        color: AuthStyle.forestDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: AuthCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        currentSlide.text,
                        key: ValueKey<int>(_currentPage),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AuthStyle.forestDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(storySlides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 22 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AuthStyle.forest
                                : AuthStyle.forest.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipStory,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AuthStyle.forest,
                              side: const BorderSide(color: Color(0xFFD8CDAE)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.storyBack),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FilledButton(
                            onPressed: _goNext,
                            style: FilledButton.styleFrom(
                              backgroundColor: AuthStyle.forest,
                              foregroundColor: AuthStyle.cream,
                              shape: const StadiumBorder(
                                side: BorderSide(
                                  color: AppColors.woodDeep,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              _currentPage < storySlides.length - 1
                                  ? l10n.storyContinue
                                  : l10n.storyExplore,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
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

List<StorySlide> _storySlides(AppLocalizations l10n) {
  return [
    StorySlide(image: AppAssets.welcome, text: l10n.storySlide1),
    StorySlide(image: AppAssets.onboardingSeed, text: l10n.storySlide2),
    StorySlide(image: AppAssets.onboardingNamePet, text: l10n.storySlide3),
    StorySlide(image: AppAssets.dailyReward, text: l10n.storySlide4),
  ];
}
