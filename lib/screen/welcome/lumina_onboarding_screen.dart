import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';

class _LuminaOnboardingSlide {
  const _LuminaOnboardingSlide({
    required this.image,
    required this.title,
    required this.body,
  });

  final String image;
  final String title;
  final String body;
}

class LuminaOnboardingScreen extends StatefulWidget {
  const LuminaOnboardingScreen({super.key});

  @override
  State<LuminaOnboardingScreen> createState() => _LuminaOnboardingScreenState();
}

class _LuminaOnboardingScreenState extends State<LuminaOnboardingScreen> {
  static const _slideDuration = Duration(seconds: 9);

  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  bool _showSkip = false;
  bool _isFinishing = false;
  bool _didPrecache = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNextSlide());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    for (final asset in _storyAssets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleNextSlide() {
    _autoSlideTimer?.cancel();
    if (!mounted || _isFinishing) return;
    _autoSlideTimer = Timer(_slideDuration, _advanceAutomatically);
  }

  Future<void> _advanceAutomatically() async {
    if (!mounted || _isFinishing) return;
    if (_currentPage >= _storyAssets.length - 1) {
      await _finishOnboarding();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    _isFinishing = true;
    _autoSlideTimer?.cancel();
    await context.read<GameStateProvider>().setHasSeenStory(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/seed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = _storySlides(context);
    final currentSlide = slides[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.inkDark,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          if (!_showSkip) setState(() => _showSkip = true);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _scheduleNextSlide();
              },
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      slides[index].image,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x1A1E2D18),
                            Color(0x001E2D18),
                            Color(0x331E2D18),
                            Color(0xB31E2418),
                          ],
                          stops: [0, 0.42, 0.66, 1],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: List.generate(slides.length, (index) {
                              return Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  height: index == _currentPage ? 5 : 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index <= _currentPage
                                        ? AppColors.creamLight
                                        : AppColors.authCard.withValues(
                                            alpha: 0.4,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: index == _currentPage
                                        ? const [
                                            BoxShadow(
                                              color: AppColors.woodDeep,
                                              blurRadius: 3,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentPage + 1}/${slides.length}',
                          style: const TextStyle(
                            color: AppColors.authCard,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: AppColors.woodDeep, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IgnorePointer(
                        ignoring: !_showSkip,
                        child: AnimatedOpacity(
                          opacity: _showSkip ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: _SkipButton(
                            label: l10n.storySkip,
                            onPressed: _finishOnboarding,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey(_currentPage),
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        decoration: BoxDecoration(
                          color: AppColors.authCard.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.wood, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameButtonLabel(
                              currentSlide.title,
                              fontSize: 21,
                              color: AppColors.woodDeep,
                              outlineColor: AppColors.creamLight,
                              outlineWidth: 3.5,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currentSlide.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.inkBrown,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.48,
                              ),
                            ),
                            if (_currentPage == 0 && !_showSkip) ...[
                              const SizedBox(height: 10),
                              Text(
                                Localizations.localeOf(context).languageCode ==
                                        'vi'
                                    ? 'Nhấn giữ màn hình để hiện nút Bỏ qua'
                                    : 'Press and hold to reveal Skip',
                                style: TextStyle(
                                  color: AppColors.outlineBrown.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isFinishing)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.creamLight),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authCard.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.woodDeep, width: 1.7),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.woodDeep,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

const _storyAssets = [
  AppAssets.onboardingStory01,
  AppAssets.onboardingStory02,
  AppAssets.onboardingStory03,
  AppAssets.onboardingStory04,
  AppAssets.onboardingStory05,
  AppAssets.onboardingStory06,
];

List<_LuminaOnboardingSlide> _storySlides(BuildContext context) {
  final isVi = Localizations.localeOf(context).languageCode == 'vi';
  if (!isVi) {
    return const [
      _LuminaOnboardingSlide(
        image: AppAssets.onboardingStory01,
        title: 'Luminara Shines',
        body:
            'Luminara is a world sustained by movement. Footsteps, beating wings, flowing water, and rustling leaves create Life Force that returns to its core and makes the entire planet glow.',
      ),
      _LuminaOnboardingSlide(
        image: AppAssets.onboardingStory02,
        title: 'The Silent Night',
        body:
            'One day, movement began to fade. Streams weakened, waterfalls hung motionless, energy veins broke apart, and Luminara’s core was left with one final pulse of light.',
      ),
      _LuminaOnboardingSlide(
        image: AppAssets.onboardingStory03,
        title: 'The Last Seed',
        body:
            'The remaining Life Force was placed inside the Lumina Seed. Carried by the Guiding Device, it left Luminara in hope of finding a new source of movement.',
      ),
      _LuminaOnboardingSlide(
        image: AppAssets.onboardingStory04,
        title: 'The Guiding Device Waits',
        body:
            'The device fell to Earth and rested beneath the roots of an ancient tree for many seasons. Animals passed by, but none could wake it. It patiently waited for a compatible rhythm of footsteps.',
      ),
      _LuminaOnboardingSlide(
        image: AppAssets.onboardingStory05,
        title: 'The First Footstep',
        body:
            'The player stepped onto the forest path. That first step created a golden ripple of Life Force, flowing through soil, stone, and roots before reaching the device.',
      ),
      _LuminaOnboardingSlide(
        image: AppAssets.onboardingStory06,
        title: 'Lumina Awakens',
        body:
            'The device opened and Sprout Lumina awoke. Its heart began to shine, plants came back to life, and a path of light opened toward the journey ahead.',
      ),
    ];
  }

  return const [
    _LuminaOnboardingSlide(
      image: AppAssets.onboardingStory01,
      title: 'Lumina Rực Sáng',
      body:
          'Lumina là một thế giới được nuôi sống bằng chuyển động. Bước chân, nhịp cánh, dòng nước và lá cây đều sinh ra Sinh Mệnh Lực, truyền về lõi và làm cả hành tinh bừng sáng.',
    ),
    _LuminaOnboardingSlide(
      image: AppAssets.onboardingStory02,
      title: 'Đêm Tĩnh Lặng',
      body:
          'Một ngày, các chuyển động dần ngừng lại. Suối yếu đi, thác nước lơ lửng, những mạch năng lượng đứt đoạn và lõi Luminara chỉ còn một nhịp sáng cuối cùng.',
    ),
    _LuminaOnboardingSlide(
      image: AppAssets.onboardingStory03,
      title: 'Mầm Cuối Cùng',
      body:
          'Phần Sinh Mệnh Lực còn sót lại được gửi vào Mầm Lumina. Mầm được đặt trong Thiết Bị Dẫn Lối và rời Luminara, mang theo hy vọng tìm được một nguồn chuyển động mới.',
    ),
    _LuminaOnboardingSlide(
      image: AppAssets.onboardingStory04,
      title: 'Thiết Bị Dẫn Lối Chờ Đợi',
      body:
          'Thiết bị rơi xuống Trái Đất, nằm dưới rễ một cây cổ thụ suốt nhiều mùa. Động vật đi ngang nhưng không đánh thức nó. Thiết bị vẫn kiên nhẫn chờ một nhịp bước chân tương thích.',
    ),
    _LuminaOnboardingSlide(
      image: AppAssets.onboardingStory05,
      title: 'Bước Chân Đầu Tiên',
      body:
          'Người chơi bước xuống con đường rừng. Bước chân ấy tạo ra một gợn Sinh Mệnh Lực vàng, chạy qua đất, đá và rễ cây rồi truyền vào thiết bị.',
    ),
    _LuminaOnboardingSlide(
      image: AppAssets.onboardingStory06,
      title: 'Lumina Thức Giấc',
      body:
          'Thiết bị mở ra và Lumina Dạng Mầm tỉnh giấc. Trái tim Lumina sáng lên, cây cỏ bắt đầu hồi sinh và một con đường ánh sáng mở về phía trước.',
    ),
  ];
}
