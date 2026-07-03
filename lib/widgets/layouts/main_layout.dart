import 'package:flutter/material.dart';
import '../common/bottom_navigation.dart'; // Sửa lại đường dẫn nếu chưa đúng

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng Stack để chồng các Widget lên nhau theo trục Z
      body: Stack(
        children: [
          // 1. Màn hình nội dung chính chiếm toàn bộ diện tích bên dưới
          Positioned.fill(child: child),

          // 2. Bottom Navigation nổi lên phía trên
          Positioned(
            bottom: 24, // Tương đương bottom-6 trong Tailwind
            left: 24, // Căn lề trái
            right: 24, // Căn lề phải để tự động giãn chiều ngang vừa vặn
            child: const BottomNavigation(), // Gọi navbar của bạn ở đây
          ),
        ],
      ),
    );
  }
}
