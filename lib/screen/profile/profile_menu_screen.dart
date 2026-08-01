import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../data/datasources/remote/achievement_screen_datasource.dart';
import '../../data/repositories/achievement_screen_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  int? _achievementCount;
  bool _isAchievementCountLoading = true;
  String? _achievementCountError;
  late final AchievementScreenRepository _achievementRepository;

  @override
  void initState() {
    super.initState();
    _achievementRepository = AchievementScreenRepository(
      AchievementScreenDatasource(ApiClient()),
    );
    _loadAchievementCount();

    // ── TỰ ĐỘNG GỌI API KHI VỪA VÀO MÀN HÌNH ─────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameStateProvider>().fetchProfileDetail();
    });
  }

  Future<void> _loadAchievementCount() async {
    try {
      final achievements = await _achievementRepository.getAchievements();
      if (!mounted) return;
      setState(() {
        // Count only achievements that have been claimed (moved to "Đã Nhận").
        // Previously used `isUnlocked` which included completed-but-unclaimed items.
        _achievementCount = achievements
            .where((item) => item.claimedAt != null)
            .length;
        _isAchievementCountLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _achievementCountError = e.toString();
        _isAchievementCountLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = theme.colorScheme.surface;

    // ── Lấy trực tiếp màu nền Scaffold tối từ hệ thống Theme ──
    final backgroundColor = theme.scaffoldBackgroundColor;

    final mutedColor = isDark ? Colors.white54 : Colors.black54;

    // Lấy thông tin trạng thái từ provider
    final provider = context.watch<GameStateProvider>();
    final user = provider.user;
    final isProfileLoading = provider.isProfileLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeaderButton(
                    icon: Icons.arrow_back_rounded,
                    // ── Quay về an toàn, giữ nguyên giao diện tối ──
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Text(
                    l10n.profileTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ── Nội dung chính có thể cuộn ──────────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                children: [
                  // Thẻ Profile Chính
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      // ĐA XÓA BORDER ĐỂ KHÔNG BỊ XUNG ĐỘT TOKEN MÀU KHI CHUYỂN MÀN
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Hiệu ứng Loading nhẹ nhàng khi đang kéo data từ Azure về
                        if (isProfileLoading && user == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          )
                        else ...[
                          // Khung Avatar tự động đổi chữ cái đầu
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.5,
                                ),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image:
                                  (user?.avatarUrl != null &&
                                      user!.avatarUrl.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(user.avatarUrl),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {
                                        debugPrint(
                                          "Lỗi tải ảnh avatar: $exception",
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child:
                                (user?.avatarUrl != null &&
                                    user!.avatarUrl.isNotEmpty)
                                ? const SizedBox.shrink()
                                : Text(
                                    (user?.name.isNotEmpty ?? false)
                                        ? user!.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                          ),

                          // Khung hiển thị Tên người dùng
                          Text(
                            (user?.name.isNotEmpty ?? false)
                                ? user!.name
                                : l10n.loading,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.traveler,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cụm Quản Lý & Thống Kê
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      l10n.managementStats,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      // ĐÃ XÓA BORDER TẠI ĐÂY
                    ),
                    child: Column(
                      children: [
                        _MenuItemRow(
                          icon: Icons.person_rounded,
                          asset: AppAssets.iconAvatar,
                          iconColor: Colors.blue,
                          title: l10n.accountInfo,
                          onTap: () =>
                              Navigator.pushNamed(context, '/profile/view'),
                        ),
                        _MenuItemRow(
                          icon: Icons.track_changes_rounded,
                          asset: AppAssets.iconDailyGoal,
                          iconColor: Colors.indigo,
                          title: l10n.setStepGoal,
                          onTap: () =>
                              Navigator.pushNamed(context, '/step-goal'),
                        ),
                        _MenuItemRow(
                          icon: Icons.local_fire_department_rounded,
                          asset: AppAssets.iconStreak,
                          iconColor: Colors.orange,
                          title: l10n.streak,
                          onTap: () => Navigator.pushNamed(context, '/streak'),
                        ),
                        _MenuItemRow(
                          icon: Icons.bar_chart_rounded,
                          iconColor: Colors.teal,
                          title: l10n.activityStats,
                          onTap: () =>
                              Navigator.pushNamed(context, '/profile/activity'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cụm Thành Tựu
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      l10n.achievements,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      // ĐÃ XÓA BORDER TẠI ĐÂY
                    ),
                    child: _MenuItemRow(
                      icon: Icons.emoji_events_rounded,
                      iconColor: Colors.amber,
                      title: l10n.achievementVault,
                      subtitle: _isAchievementCountLoading
                          ? l10n.loading
                          : _achievementCountError != null
                          ? l10n.achievementsLoadFailed
                          : l10n.achievementsCollected(_achievementCount ?? 0),
                      onTap: () =>
                          Navigator.pushNamed(context, '/profile/achievements'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        // ĐÃ XÓA BORDER TẠI ĐÂY
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AppIcon(
            icon,
            size: 20,
            // SỬA LỖI CHUYỂN MODE: Ăn màu trực tiếp từ token onSurface của hệ thống
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItemRow({
    required this.icon,
    this.asset,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  // ĐÃ XÓA BORDER TẠI ĐÂY
                ),
                child: AppIcon(icon, asset: asset, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppIcon(
                Icons.chevron_right_rounded,
                size: 20,
                color: mutedColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
