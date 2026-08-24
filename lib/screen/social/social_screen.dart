import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/game_button_label.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _activeTabIndex = 0; // 0: Bạn Bè, 1: Xếp Hạng

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.buttonGreen;

    return Scaffold(
      backgroundColor: Colors.transparent, // Bắt buộc để kế thừa MainLayout
      body: Column(
        children: [
          // Header & Tab Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Column(
              children: [
                GameButtonLabel(
                  l10n.socialTitle,
                  fontSize: 20,
                  color: textColor,
                  outlineColor: isDark
                      ? AppColors.darkTextOutline
                      : AppColors.authCard,
                  outlineWidth: 4,
                ),
                const SizedBox(height: 16),

                // Container Thanh Tab trượt
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkCard : AppColors.authCard)
                        .withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.wood, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Khối màu nền trượt mượt mà (Layout ID Animation)
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        alignment: _activeTabIndex == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.woodDeep,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Text của Tab
                      Row(
                        children: [
                          _buildTabItem(0, l10n.socialFriends),
                          _buildTabItem(1, l10n.socialLeaderboard),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vùng hiển thị Nội dung Component con
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              // THÊM ĐOẠN LAYOUT BUILDER NÀY VÀO ĐÂY
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      fit: StackFit.expand, // Cứu tinh của lỗi RenderFlex ở đây
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
              child: _activeTabIndex == 0
                  ? const FriendsScreen(
                      key: ValueKey(
                        'friends_tab',
                      ), // Đừng quên giữ lại ValueKey
                      isEmbedded: true,
                    )
                  : const LeaderboardScreen(
                      key: ValueKey('leaderboard_tab'),
                      isEmbedded: true,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: isActive
              ? GameButtonLabel(label, fontSize: 14, outlineWidth: 2.4)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkForeground
                        : AppColors.woodDeep,
                  ),
                ),
        ),
      ),
    );
  }
}
