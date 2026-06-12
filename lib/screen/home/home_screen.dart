import 'dart:ui'; // Bắt buộc phải có để sử dụng BackdropFilter (giả lập backdrop-blur)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_state_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameState = Provider.of<GameStateProvider>(context);
    final user = gameState.user;

    // Giả lập các biến tính toán bước chân giống như React
    final int dailySteps = user?.steps ?? 6420;
    const int goalSteps = 10000;
    final double stepPct = (dailySteps / goalSteps).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent, // Giữ nền trong suốt như Figma
      body: SafeArea(
        // CHUYỂN SANG DÙNG STACK ĐỂ ĐẶT CÁC NÚT NỔI LÊN TRÊN NỀN
        child: Stack(
          children: [
            // Nội dung trống phía dưới (Khu vực nuôi pet & dashboard sau này)
            const Positioned.fill(child: Center(child: SizedBox.shrink())),

            // ─── TOP HEADER THẲNG HÀNG (BƯỚC CHÂN, GIỌT SƯƠNG, LEVEL) ───
            Positioned(
              top: 24, // pt-6 ứng với 24px trong Figma
              left: 24, // px-6 ứng với 24px trong Figma
              right: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. THANH ĐẾM BƯỚC CHÂN (Bên trái - Tự co giãn)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_walk,
                                    size: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Hôm Nay",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${dailySteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 10,000",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Thanh Progress Bar
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: stepPct,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. KHUNG GIỌT SƯƠNG (Ở giữa) - BẠN ĐÃ COMMENT KHỐI NÀY NÊN MÌNH GIỮ NGUYÊN COMMENT
                  // Container(
                  //   height: 36,
                  //   padding: const EdgeInsets.symmetric(horizontal: 12),
                  //   decoration: BoxDecoration(
                  //     color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  //     borderRadius: BorderRadius.circular(18),
                  //     border: Border.all(
                  //       color: theme.colorScheme.outlineVariant,
                  //     ),
                  //   ),
                  //   child: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       const Icon(
                  //         Icons.opacity,
                  //         size: 16,
                  //         color: Colors.blueAccent,
                  //       ),
                  //       const SizedBox(width: 6),
                  //       Text(
                  //         "1,240",
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           fontWeight: FontWeight.w900,
                  //           color: theme.colorScheme.onSurface,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(width: 8),

                  // 3. KHUNG LEVEL / PROFILE (Bên phải) - Đã xóa viền Border hoàn toàn để giống Figma
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8,
                          sigmaY: 8,
                        ), // backdrop-blur-sm
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.only(left: 8, right: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(
                              0.7,
                            ), // bg-card/70
                            borderRadius: BorderRadius.circular(18),
                            // Đã loại bỏ hoàn toàn Border.all ở đây
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  size: 11,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Lv. ${user?.level ?? 1}",
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
            ),

            // ─── CỤM NÚT NỔI BÊN TRÁI (Settings, Lịch, Nhiệm vụ) ───
            Positioned(
              top: 84, // Đẩy xuống một chút tương đương top-24 trong Figma
              left: 24,
              child: Column(
                children: [
                  _buildFloatingIconBtn(
                    context: context,
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  const SizedBox(height: 16),
                  // _buildFloatingIconBtn(
                  //   context: context,
                  //   icon: Icons.calendar_today_outlined,
                  //   hasBadge: true, // Chấm cam thông báo
                  //   onTap: () => Navigator.pushNamed(context, '/daily-reward'),
                  // ),
                  // const SizedBox(height: 16),
                  // _buildFloatingIconBtn(
                  //   context: context,
                  //   icon: Icons.receipt_long_outlined,
                  //   hasBadge: true, // Chấm cam thông báo
                  //   onTap: () => Navigator.pushNamed(context, '/quests'),
                  // ),
                ],
              ),
            ),

            // ─── CỤM NÚT NỔI BÊN PHẢI (Chuông thông báo) ───
            // Positioned(
            //   top: 72,
            //   right: 24,
            //   child: _buildFloatingIconBtn(
            //     context: context,
            //     icon: Icons.notifications_none_outlined,
            //     hasBadge: true, // Chấm cam thông báo
            //     onTap: () => Navigator.pushNamed(context, '/notifications'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // ─── HÀM HỖ TRỢ TẠO NÚT TRÒN (Đã sửa đổi: Xóa viền hoàn toàn, chỉnh kích thước chuẩn 40px) ───
  Widget _buildFloatingIconBtn({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, // w-10 chuẩn Figma là 40px
        height: 40, // h-10 chuẩn Figma là 40px
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // bg-card
          shape: BoxShape.circle,
          // Đã loại bỏ Border.all ở đây để không còn viền quanh nút tròn nữa
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.05,
              ), // shadow-sm tương đương alpha 0.05
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 20, // Kích thước icon 20px đồng bộ Figma
              color: theme.colorScheme.onSurface,
            ),
            // Vẽ cái chấm thông báo nếu có
            if (hasBadge)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10, // w-2.5 tương đương 10px
                  height: 10, // h-2.5 tương đương 10px
                  decoration: BoxDecoration(
                    color: Colors
                        .orangeAccent, // Màu cam accent chuẩn thông báo của bạn
                    shape: BoxShape.circle,
                    // Sử dụng màu nền của chính nút bấm làm viền để tách biệt với icon (giống border-card trong CSS)
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
}
