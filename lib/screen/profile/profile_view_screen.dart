import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/step_tracking_provider.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động gọi API lấy thông tin Profile từ Database ngay khi mở màn hình lên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameStateProvider>().fetchProfileDetail();
    });
  }

  // Hàm helper dùng để chuyển đổi chuỗi định dạng từ API ISO (yyyy-MM-ddTHH:mm:ss) sang dd/MM/yyyy
  String _formatJoinDate(String? rawDate, AppLocalizations l10n) {
    if (rawDate == null || rawDate.isEmpty) return l10n.notUpdated;
    try {
      // Ép kiểu chuỗi của Backend trả về sang đối tượng DateTime
      final parsedDate = DateTime.parse(rawDate);
      // Trả về chuỗi định dạng dd/MM/yyyy sạch đẹp
      final day = parsedDate.day.toString().padLeft(2, '0');
      final month = parsedDate.month.toString().padLeft(2, '0');
      final year = parsedDate.year;
      return '$day/$month/$year';
    } catch (e) {
      // Phòng hờ nếu biến joinDate của bồ trong model đã được định dạng sẵn trước đó rồi
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.outlineBrown;
    final cardColor = isDark ? AppColors.darkCard : AppColors.authCard;
    final l10n = AppLocalizations.of(context);
    // Lắng nghe liên tục sự thay đổi dữ liệu từ GameStateProvider
    final provider = context.watch<GameStateProvider>();
    final user = provider.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GameBackButton(
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                  ),
                  GameButtonLabel(
                    l10n.accountInfo,
                    fontSize: 20,
                    color: textColor,
                    outlineColor: isDark ? AppColors.darkBorder : AppColors.authCard,
                    outlineWidth: 4,
                  ),
                  _HeaderIconButton(
                    icon: Icons.edit_rounded,
                    asset: AppAssets.iconEditProfile,
                    iconColor: textColor,
                    onTap: () {
                      Navigator.pushNamed(context, '/profile/edit');
                    },
                  ),
                ],
              ),
            ),

            // ── Xử lý các trạng thái UI: Loading, Lỗi, và Có dữ liệu ─────────
            Expanded(
              child: Builder(
                builder: (context) {
                  // 1. Nếu hệ thống đang gọi API: Hiển thị vòng xoay Loading tinh tế
                  if (provider.isProfileLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }

                  // 2. Nếu có lỗi xảy ra (Mất mạng, Token hết hạn, API sập...): Hiển thị nút Thử lại
                  if (provider.profileErrorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(
                              Icons.wifi_off_rounded,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.profileErrorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => provider.fetchProfileDetail(),
                              icon: const AppIcon(Icons.refresh_rounded),
                              label: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 3. Nếu dữ liệu trống (Chưa đăng nhập hoặc lỗi logic)
                  if (user == null) {
                    return Center(child: Text(l10n.characterNotFound));
                  }

                  // Kiểm tra trạng thái trống của bio để hiển thị "Chưa cập nhật" hay chữ thường
                  final normalizedBio = user.bio.trim().toLowerCase();
                  final bool isBioEmpty =
                      normalizedBio.isEmpty ||
                      normalizedBio == l10n.notUpdated.toLowerCase() ||
                      normalizedBio == 'chưa cập nhật' ||
                      normalizedBio == 'chưa có tiểu sử' ||
                      normalizedBio == 'no bio' ||
                      normalizedBio == 'not updated';

                  // 4. HIỂN THỊ DỮ LIỆU TỪ DATABASE THÀNH CÔNG
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    children: [
                      // Avatar Section
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkMuted : AppColors.leafLight).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.oliveDeep,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.woodDeep.withValues(alpha: 0.2),
                              blurRadius: 9,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.authCard.withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.wood,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: AppColors.leafLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                            color: textColor,
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
                                ),
                                alignment: Alignment.center,
                                child: (user.avatarUrl.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.network(
                                          user.avatarUrl,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : 'W',
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                            color: textColor,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : 'W',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                            color: textColor,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isBioEmpty ? l10n.notUpdated : user.bio,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: isBioEmpty
                                      ? mutedColor
                                      : AppColors.oliveDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Khối thông tin chi tiết lấy từ GameUser (sau khi đã map dữ liệu sạch từ DB)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.97),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.wood,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.woodDeep.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.mail_rounded,
                              label: 'Email',
                              value: user.email,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.creamDeep,
                            ),
                            _DetailRow(
                              icon: Icons.calendar_month_rounded,
                              label: l10n.dateOfBirth,
                              value: user.dob,
                              fallback: l10n.notUpdated,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.creamDeep,
                            ),
                            _DetailRow(
                              icon: Icons.person_rounded,
                              asset: AppAssets.iconAvatar,
                              label: l10n.gender,
                              value: switch (user.gender.toLowerCase()) {
                                'male' => l10n.genderMale,
                                'female' => l10n.genderFemale,
                                'other' => l10n.genderOther,
                                _ => user.gender,
                              },
                              fallback: l10n.notUpdated,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.creamDeep,
                            ),
                            _DetailRow(
                              icon: Icons.card_membership_rounded,
                              label: l10n.joinDate,
                              // ĐÃ ĐỊNH DẠNG LẠI CHUỖI CREATEDAT SANG DD/MM/YYYY TẠI ĐÂY
                              value: _formatJoinDate(user.joinDate, l10n),
                              fallback: l10n.notUpdated,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng xuất
                      ElevatedButton(
                        onPressed: () async {
                          await context
                              .read<StepTrackingProvider>()
                              .stopForUser();
                          await context.read<GameStateProvider>().logout();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/auth/login',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonYellow,
                          foregroundColor: AppColors.buttonText,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(
                            side: BorderSide(
                              color: AppColors.woodDeep,
                              width: 2,
                            ),
                          ),
                          elevation: 2,
                        ),
                        child: GameButtonLabel(
                          l10n.logout,
                          fontSize: 15,
                          color: AppColors.buttonText,
                          outlineColor: AppColors.woodDeep,
                          outlineWidth: 2.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Các Widget Phụ Trợ (Giữ nguyên cấu trúc giao diện đẹp mắt của bồ) ──────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final VoidCallback onTap;
  final Color? iconColor;

  const _HeaderIconButton({
    required this.icon,
    this.asset,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: GameBackButton.buttonSize,
      height: GameBackButton.buttonSize,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.authCard.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.woodDeep,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDeep.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AppIcon(
            icon,
            asset: asset,
            size: 27,
            color: iconColor ?? AppColors.woodDeep,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final String label;
  final String value;
  final String fallback;

  const _DetailRow({
    required this.icon,
    this.asset,
    required this.label,
    required this.value,
    this.fallback = '',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.outlineBrown;
    final valueColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkMuted : AppColors.creamLight,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.wood,
                    width: 1.2,
                  ),
                ),
                child: AppIcon(icon, asset: asset, size: 22, color: mutedColor),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : fallback,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
