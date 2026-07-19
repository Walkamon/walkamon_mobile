import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/step_tracking_provider.dart';

// ── Dewdrop Icon (SVG → CustomPaint) ────────────────────────────────────────
class _DewdropIcon extends StatelessWidget {
  const _DewdropIcon({this.size = 16, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DewdropPainter(color: color ?? Colors.blue),
    );
  }
}

class _DewdropPainter extends CustomPainter {
  const _DewdropPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final sx = size.width / 24;
    final sy = size.height / 24;

    final path = Path()
      ..moveTo(12 * sx, 2.5 * sy)
      ..cubicTo(12 * sx, 2.5 * sy, 4.5 * sx, 9.5 * sy, 4.5 * sx, 14 * sy)
      ..cubicTo(4.5 * sx, 18.14 * sy, 7.86 * sx, 21.5 * sy, 12 * sx, 21.5 * sy)
      ..cubicTo(
        16.14 * sx,
        21.5 * sy,
        19.5 * sx,
        18.14 * sy,
        19.5 * sx,
        14 * sy,
      )
      ..cubicTo(19.5 * sx, 9.5 * sy, 12 * sx, 2.5 * sy, 12 * sx, 2.5 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DewdropPainter oldDelegate) => oldDelegate.color != color;
}

// ── Swords Icon (CustomPaint) ──────────────────────────────────────────────
class _SwordsIcon extends StatelessWidget {
  const _SwordsIcon({this.size = 22, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SwordsPainter(color: color ?? Colors.white),
    );
  }
}

class _SwordsPainter extends CustomPainter {
  const _SwordsPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.drawLine(
      Offset(w * 0.25, h * 0.75),
      Offset(w * 0.75, h * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.2, h * 0.55),
      Offset(w * 0.45, h * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.75, h * 0.75),
      Offset(w * 0.25, h * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.8, h * 0.55),
      Offset(w * 0.55, h * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SwordsPainter oldDelegate) => oldDelegate.color != color;
}

// ── StatBar Widget ──────────────────────────────────────────────────────────
class _StatBar extends StatefulWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.barColor,
  });
  final String label;
  final int value;
  final Color barColor;

  @override
  State<_StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<_StatBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: mutedFg,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.value / 100.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text(
            '${widget.value}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ── Floating Dew Bubble ─────────────────────────────────────────────────────
class _FloatingBubble {
  _FloatingBubble({
    required this.id,
    required this.top,
    required this.left,
    required this.size,
  });
  final int id;
  final double top; // fraction 0-1
  final double left; // fraction 0-1
  final double size;
}

// ── Main HomeScreen ─────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _feedAnim = false;
  bool _stepExpanded = false;
  Timer? _refreshTimer;
  final List<_FloatingNum> _floatingNums = [];
  final List<_FloatingBubble> _bubbles = [
    _FloatingBubble(id: 1, top: 0.20, left: 0.12, size: 30),
    _FloatingBubble(id: 2, top: 0.18, left: 0.72, size: 38),
    _FloatingBubble(id: 3, top: 0.55, left: 0.08, size: 26),
    _FloatingBubble(id: 4, top: 0.60, left: 0.78, size: 32),
  ];

  // Glow animation
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  // Feed ripple animation
  late final AnimationController _rippleCtrl;

  // Tap hint blink
  late final AnimationController _hintCtrl;

  @override
  void initState() {
    super.initState();

    // Glow pulse behind pet
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowScale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowOpacity = Tween<double>(
      begin: 0.35,
      end: 0.65,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Feed ripple
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Hint blink
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Fetch pet status from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = context.read<GameStateProvider>();
      if (gameState.isAuthenticated) {
        unawaited(gameState.fetchPetStatus());
      }
    });

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;

      final gameState = context.read<GameStateProvider>();
      if (gameState.isAuthenticated) {
        unawaited(gameState.fetchPetStatus());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _glowCtrl.dispose();
    _rippleCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  String _getMood(int bondingLevel) {
    if (bondingLevel > 80) return 'excited';
    if (bondingLevel > 40) return 'happy';
    if (bondingLevel < 10) return 'sleepy';
    return 'neutral';
  }

  void _handlePetTap(GameStateProvider gameState) async {
    final success = await gameState.tapSpirit();

    if (!success) {
      // Handle error if needed
      return;
    }

    setState(() {
      _feedAnim = true;
      final id = DateTime.now().millisecondsSinceEpoch;
      _floatingNums.add(
        _FloatingNum(id: id, xOffset: (math.Random().nextDouble() * 40 - 20)),
      );
    });

    _rippleCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _feedAnim = false);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _floatingNums.removeWhere(
            (n) => n.id == _floatingNums.firstOrNull?.id,
          );
        });
      }
    });
  }

  void _handleDewdropTap(GameStateProvider gameState) async {
    await gameState.feedSpirit();
  }

  void _collectBubble(int id, GameStateProvider gameState) {
    setState(() {
      _bubbles.removeWhere((b) => b.id == id);
    });
    _handleDewdropTap(gameState);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final gameState = Provider.of<GameStateProvider>(context);
    final user = gameState.user;

    // Giả lập các biến tính toán bước chân giống như React
    final int dailySteps = context.watch<StepTrackingProvider>().dailySteps;
    const int goalSteps = 10000;
    final double stepPct = (dailySteps / goalSteps).clamp(0.0, 1.0);

    final dewColor = isDark ? AppColors.darkDew : AppColors.lightDew;
    final luminaGlow = isDark
        ? AppColors.darkLuminaGlow
        : AppColors.lightLuminaGlow;
    final mutedFg = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final energyColor = isDark ? AppColors.darkDew : AppColors.lightDew;
    final lifeColor = isDark ? AppColors.darkLife : AppColors.lightLife;
    final bondColor = isDark ? AppColors.darkBond : AppColors.lightBond;
    final int bondingLevel = gameState.bondingLevel;
    final int spiritLevel = gameState.spiritLevel;
    final int spiritExp = gameState.spiritExp;
    final int spiritEnergy = gameState.spiritEnergy;
    final int spiritHealth = gameState.spiritHealth;
    final String spiritName = gameState.spiritName;
    final String spiritInfo = gameState.spiritInfo;
    final bool isLoggedIn = gameState.isAuthenticated;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: _buildBottomNavigation(context),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main scrollable content ──
            Column(
              children: [
                // ── Top Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Warning message
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(minHeight: 36),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF8FAF8F)
                                      : const Color(0xFF253426),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '12+',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Chơi game quá 180 phút một ngày sẽ ảnh hưởng xấu đến sức khỏe',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 2. Step bar (compact -> expands on tap)
                          GestureDetector(
                            key: const ValueKey('step_compact'),
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 24,
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    18,
                                    16,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 18,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.directions_walk,
                                                size: 14,
                                                color: mutedFg,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Hôm Nay',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: mutedFg,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${_formatNumber(dailySteps)} / ${_formatNumber(goalSteps)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: stepPct),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (_, val, __) => Container(
                                          height: 10,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkMuted
                                                : AppColors.lightMuted,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: val,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: primary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Số bước chân bạn đã đi trong ngày hôm nay',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(
                                  0.75,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_walk,
                                    size: 14,
                                    color: mutedFg,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Step',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 3. Dewdrop currency
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _DewdropIcon(size: 16, color: dewColor),
                                const SizedBox(width: 6),
                                Text(
                                  '1,240',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 4. Level / Profile
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/profile'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: primary.withOpacity(
                                          0.2,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 11,
                                          color: primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isLoggedIn
                                            ? 'Lv. ${user?.level ?? 1}'
                                            : 'Lv. 1',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Pet Area ──────────────────────────────────────────
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Concentric Circles (Waves/Radar effect) ──
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _glowScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer circle (280px)
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: luminaGlow.withOpacity(0.03),
                                  border: Border.all(
                                    color: luminaGlow.withOpacity(0.05),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Middle circle (210px)
                              Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: luminaGlow.withOpacity(0.06),
                                  border: Border.all(
                                    color: luminaGlow.withOpacity(0.09),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Inner circle (140px)
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: luminaGlow.withOpacity(0.12),
                                  border: Border.all(
                                    color: luminaGlow.withOpacity(0.15),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Floating dew bubbles (drawn on top of the circles)
                      ..._bubbles.map(
                        (bubble) => _BubbleWidget(
                          key: ValueKey(bubble.id),
                          bubble: bubble,
                          dewColor: dewColor,
                          onCollect: () => _collectBubble(bubble.id, gameState),
                        ),
                      ),

                      // Pet sprite placeholder
                      GestureDetector(
                        onTap: () => _handlePetTap(gameState),
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Pet visual
                              _LuminaSprite(
                                mood: _getMood(bondingLevel),
                                primary: primary,
                                luminaGlow: luminaGlow,
                              ),

                              // Floating "+♥" numbers on feed
                              ..._floatingNums.map(
                                (n) => _FloatingHeartWidget(
                                  key: ValueKey(n.id),
                                  xOffset: n.xOffset,
                                  primary: primary,
                                ),
                              ),

                              // Ripple pulse on feed tap
                              if (_feedAnim)
                                AnimatedBuilder(
                                  animation: _rippleCtrl,
                                  builder: (_, __) => Transform.scale(
                                    scale: 0.6 + _rippleCtrl.value * 1.1,
                                    child: Opacity(
                                      opacity: (1 - _rippleCtrl.value).clamp(
                                        0,
                                        1,
                                      ),
                                      child: Container(
                                        width: 220,
                                        height: 220,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: luminaGlow,
                                            width: 4,
                                          ),
                                        ),
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

                // ── Status Dashboard & Feed Button ────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 30),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Box Trạng thái
                      Padding(
                        padding: const EdgeInsets.only(top: 60, right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(
                                  0.85,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/spirit/detail',
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'TRẠNG THÁI LUMINA',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  color: mutedFg,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                spiritName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/spirit/detail',
                                        ),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkMuted
                                                : AppColors.lightMuted,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'i',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: mutedFg,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Lv. $spiritLevel',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'EXP $spiritExp/100',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: mutedFg,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    spiritInfo,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mutedFg,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _StatBar(
                                    label: 'Năng Lượng',
                                    value: spiritEnergy,
                                    barColor: energyColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatBar(
                                    label: 'Sinh Mệnh Lực',
                                    value: spiritHealth,
                                    barColor: Colors.orange,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatBar(
                                    label: 'Độ Gắn Kết',
                                    value: bondingLevel,
                                    barColor: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ), // Added missing closing parenthesis for Padding
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _handleDewdropTap(gameState),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFA1D4B1),
                              border: Border.all(
                                color: const Color(0xFF253426),
                                width: 2.5,
                              ),
                            ),
                            child: Center(
                              child: _DewdropIcon(
                                size: 28,
                                color: const Color(0xFF2A3A2C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Floating buttons: Left side ──────────────────────────
            Positioned(
              top: 84,
              left: 24,
              child: Column(
                children: [
                  // Settings
                  _buildFloatingIconBtn(
                    context: context,
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const SizedBox(height: 16),
                  // Daily Reward
                  _buildFloatingIconBtn(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    hasBadge: true,
                    onTap: () =>
                        Navigator.pushNamed(context, '/daily-login-calendar'),
                  ),
                  const SizedBox(height: 16),
                  // Missions / Quests
                  _buildFloatingIconBtn(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    hasBadge: true,
                    onTap: () => Navigator.pushNamed(context, '/missions'),
                  ),
                ],
              ),
            ),

            // ── Floating button: Right side (Notification Bell) ──────
            Positioned(
              top: 84,
              right: 24,
              child: _buildFloatingIconBtn(
                context: context,
                icon: Icons.notifications_none_outlined,
                hasBadge: true,
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Format number with commas ──
  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // ── Helper: Floating icon button ──
  Widget _buildFloatingIconBtn({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            if (hasBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkAccent
                        : AppColors.lightAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Bottom Navigation Bar with floating center item ──
  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barBgColor = isDark
        ? const Color(0xFF25332A)
        : const Color(0xFFE5DCCF);
    final activeBgColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final activeIconColor = isDark
        ? const Color(0xFF1E2E24)
        : const Color(0xFFFFF8F0);
    final inactiveColor = isDark
        ? AppColors.darkMutedForeground.withOpacity(0.6)
        : AppColors.lightMutedForeground.withOpacity(0.6);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Nav Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                iconWidget: Icon(
                  Icons.bolt_rounded,
                  size: 22,
                  color: inactiveColor,
                ),
                label: 'Cộng Đồng',
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/friends'),
              ),
              _buildNavItem(
                iconWidget: _SwordsIcon(size: 22, color: inactiveColor),
                label: 'PvP',
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/pvp'),
              ),
              const SizedBox(width: 64), // Giữ chỗ cho nút giữa nổi
              _buildNavItem(
                iconWidget: Icon(
                  Icons.backpack_outlined,
                  size: 22,
                  color: inactiveColor,
                ),
                label: 'Túi Đồ',
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/inventory'),
              ),
              _buildNavItem(
                iconWidget: Icon(
                  Icons.storefront_outlined,
                  size: 22,
                  color: inactiveColor,
                ),
                label: 'Cửa Hàng',
                color: inactiveColor,
                onTap: () => Navigator.pushNamed(context, '/shop'),
              ),
            ],
          ),

          // Floating Center Button
          Positioned(
            top: -18,
            child: GestureDetector(
              onTap: () {
                // Đang ở Trang Chủ
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeBgColor,
                      boxShadow: [
                        BoxShadow(
                          color: activeBgColor.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.home_rounded,
                        size: 28,
                        color: activeIconColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trang Chủ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.lightForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required Widget iconWidget,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lumina Sprite Widget ────────────────────────────────────────────────────
class _LuminaSprite extends StatefulWidget {
  const _LuminaSprite({
    required this.mood,
    required this.primary,
    required this.luminaGlow,
  });
  final String mood;
  final Color primary;
  final Color luminaGlow;

  @override
  State<_LuminaSprite> createState() => _LuminaSpriteState();
}

class _LuminaSpriteState extends State<_LuminaSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  String _getMoodEmoji() {
    switch (widget.mood) {
      case 'excited':
        return '😊';
      case 'happy':
        return '😊';
      case 'sleepy':
        return '😴';
      default:
        return '😊';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceCtrl,
      builder: (_, child) {
        final bounce = math.sin(_bounceCtrl.value * math.pi) * 8;
        return Transform.translate(offset: Offset(0, -bounce), child: child);
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.luminaGlow.withOpacity(0.4),
              widget.luminaGlow.withOpacity(0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa_outlined, size: 64, color: widget.primary),
              const SizedBox(height: 8),
              Text(
                'Lumina',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.primary.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Floating Heart Number ───────────────────────────────────────────────────
class _FloatingNum {
  _FloatingNum({required this.id, required this.xOffset});
  final int id;
  final double xOffset;
}

class _FloatingHeartWidget extends StatefulWidget {
  const _FloatingHeartWidget({
    super.key,
    required this.xOffset,
    required this.primary,
  });
  final double xOffset;
  final Color primary;

  @override
  State<_FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

class _FloatingHeartWidgetState extends State<_FloatingHeartWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        top: 16 - (_ctrl.value * 70),
        left: 100 + widget.xOffset - 12,
        child: Opacity(
          opacity: (1 - _ctrl.value).clamp(0, 1),
          child: Text(
            '+♥',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: widget.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bubble Widget ───────────────────────────────────────────────────────────
class _BubbleWidget extends StatefulWidget {
  const _BubbleWidget({
    super.key,
    required this.bubble,
    required this.dewColor,
    required this.onCollect,
  });
  final _FloatingBubble bubble;
  final Color dewColor;
  final VoidCallback onCollect;

  @override
  State<_BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<_BubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000 + widget.bubble.id * 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, __) {
        final yOffset = math.sin(_floatCtrl.value * math.pi) * 12;
        return Positioned(
          top:
              (widget.bubble.top * MediaQuery.of(context).size.height * 0.5) +
              yOffset,
          left: widget.bubble.left * MediaQuery.of(context).size.width,
          child: GestureDetector(
            onTap: widget.onCollect,
            child: Container(
              width: widget.bubble.size,
              height: widget.bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.dewColor.withOpacity(0.25),
                border: Border.all(
                  color: widget.dewColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: _DewdropIcon(
                  size: widget.bubble.size * 0.5,
                  color: widget.dewColor.withOpacity(0.75),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
