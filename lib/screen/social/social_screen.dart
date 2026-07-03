import 'package:flutter/material.dart';
import '../friends/friends_screen.dart';
// import 'leaderboard_screen.dart'; // Mở ra khi bạn làm màn Leaderboard

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _activeTabIndex = 0; // 0: Bạn Bè, 1: Xếp Hạng

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent, // Bắt buộc để kế thừa MainLayout
      body: Column(
        children: [
          // Header & Tab Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Column(
              children: [
                const Text(
                  'Cộng Đồng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Container Thanh Tab trượt
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.4),
                    ),
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
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                ),
                              ],
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Text của Tab
                      Row(
                        children: [
                          _buildTabItem(0, 'Bạn Bè'),
                          _buildTabItem(1, 'Xếp Hạng'),
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
                  : const Center(
                      key: ValueKey(
                        'leaderboard_tab',
                      ), // Đừng quên giữ lại ValueKey
                      child: Text('Leaderboard Screen'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isActive = _activeTabIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
              color: isActive
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
