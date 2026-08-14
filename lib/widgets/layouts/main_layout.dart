import 'package:flutter/material.dart';
import '../common/bottom_navigation.dart'; // Sửa lại đường dẫn nếu chưa đúng
import '../common/home_page_backdrop.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: HomePageBackdrop(child: child),
      bottomNavigationBar: BottomNavigation(key: ValueKey(isDark)),
    );
  }
}
