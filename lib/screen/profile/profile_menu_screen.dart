import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/constants/app_assets.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
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
    // ── Lấy trực tiếp màu nền Scaffold tối từ hệ thống Theme ──
    final backgroundColor = theme.scaffoldBackgroundColor;

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeaderButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  GameButtonLabel(
                    l10n.profileTitle,
                    fontSize: 20,
                    color: AppColors.woodDeep,
                    outlineColor: AppColors.authCard,
                    outlineWidth: 4,
                  ),
                  const SizedBox(width: GameBackButton.buttonSize),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.leafLight.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.oliveDeep, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.authCard.withValues(alpha: 0.97),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: AppColors.wood, width: 1.5),
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
                              width: 88,
                              height: 88,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.leafLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.woodDeep,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.woodDeep.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
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
                                        color: AppColors.woodDeep,
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
                                color: AppColors.woodDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.traveler,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.outlineBrown,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cụm Quản Lý & Thống Kê
                  Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: GameButtonLabel(
                      l10n.managementStats,
                      fontSize: 16,
                      color: AppColors.woodDeep,
                      outlineColor: AppColors.authCard,
                      outlineWidth: 3.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.leafLight.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.oliveDeep, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.18),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _MenuItemRow(
                          icon: Icons.person_rounded,
                          asset: AppAssets.iconProfileNav,
                          iconColor: AppColors.sky,
                          title: l10n.accountInfo,
                          onTap: () =>
                              Navigator.pushNamed(context, '/profile/view'),
                        ),
                        _MenuItemRow(
                          icon: Icons.track_changes_rounded,
                          asset: AppAssets.iconDailyGoal,
                          iconColor: AppColors.lavender,
                          title: l10n.setStepGoal,
                          onTap: () =>
                              Navigator.pushNamed(context, '/step-goal'),
                        ),
                        _MenuItemRow(
                          icon: Icons.local_fire_department_rounded,
                          asset: AppAssets.iconStreak,
                          iconColor: AppColors.amber,
                          title: l10n.streak,
                          onTap: () => Navigator.pushNamed(context, '/streak'),
                        ),
                        _MenuItemRow(
                          icon: Icons.bar_chart_rounded,
                          iconColor: AppColors.olive,
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
                    child: GameButtonLabel(
                      l10n.achievements,
                      fontSize: 16,
                      color: AppColors.woodDeep,
                      outlineColor: AppColors.authCard,
                      outlineWidth: 3.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.leafLight.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.oliveDeep, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.woodDeep.withValues(alpha: 0.18),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _MenuItemRow(
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.gold,
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
    return GameBackButton(
      key: ValueKey(icon),
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onTap,
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
    const mutedColor = AppColors.outlineBrown;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: AppColors.authCard.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.wood, width: 1.35),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.creamLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.wood, width: 1.4),
                    ),
                    child: AppIcon(
                      icon,
                      asset: asset,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.woodDeep,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const AppIcon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: AppColors.woodDeep,
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
