import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _formatJoinDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Chưa cập nhật';
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
    final cardColor = theme.colorScheme.surface;
    final backgroundColor = theme.colorScheme.surfaceTint.withValues(
      alpha: 0.02,
    );
    final borderColor = theme.dividerColor.withValues(alpha: 0.1);

    // Lắng nghe liên tục sự thay đổi dữ liệu từ GameStateProvider
    final provider = context.watch<GameStateProvider>();
    final user = provider.user;

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
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Text(
                    'Thông tin tài khoản',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Icons.edit_rounded,
                    iconColor: theme.colorScheme.primary,
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
                            Icon(
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
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 3. Nếu dữ liệu trống (Chưa đăng nhập hoặc lỗi logic)
                  if (user == null) {
                    return const Center(
                      child: Text('Không tìm thấy thông tin nhân vật.'),
                    );
                  }

                  // Kiểm tra trạng thái trống của bio để hiển thị "Chưa cập nhật" hay chữ thường
                  final bool isBioEmpty =
                      user.bio.trim().isEmpty || user.bio == 'Chưa cập nhật';

                  // 4. HIỂN THỊ DỮ LIỆU TỪ DATABASE THÀNH CÔNG
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    children: [
                      // Avatar Section
                      Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardColor, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
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
                                          color: theme.colorScheme.onPrimary,
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
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isBioEmpty ? 'Chưa cập nhật' : user.bio,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: isBioEmpty
                                  ? Colors.grey
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Khối thông tin chi tiết lấy từ GameUser (sau khi đã map dữ liệu sạch từ DB)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Divider(height: 1, color: borderColor),
                            _DetailRow(
                              icon: Icons.mail_rounded,
                              label: 'Email',
                              value: user.email,
                            ),
                            Divider(height: 1, color: borderColor),
                            _DetailRow(
                              icon: Icons.calendar_month_rounded,
                              label: 'Ngày sinh',
                              value: user.dob,
                            ),
                            Divider(height: 1, color: borderColor),
                            _DetailRow(
                              icon: Icons.person_rounded,
                              label: 'Giới tính',
                              value: switch (user.gender.toLowerCase()) {
                                'male' => 'Nam',
                                'female' => 'Nữ',
                                'other' => 'Khác',
                                _ => user.gender,
                              },
                            ),
                            Divider(height: 1, color: borderColor),
                            _DetailRow(
                              icon: Icons.card_membership_rounded,
                              label: 'Ngày tham gia',
                              // ĐÃ ĐỊNH DẠNG LẠI CHUỖI CREATEDAT SANG DD/MM/YYYY TẠI ĐÂY
                              value: _formatJoinDate(user.joinDate),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng xuất
                      ElevatedButton(
                        onPressed: () async {
                          await context.read<StepTrackingProvider>().stopForUser();
                          await context.read<GameStateProvider>().logout();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/auth/login',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Đăng xuất tài khoản',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
  final VoidCallback onTap;
  final Color? iconColor;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            color:
                iconColor ??
                (theme.brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: mutedColor),
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
          Text(
            value.isNotEmpty ? value : 'Chưa cập nhật',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
