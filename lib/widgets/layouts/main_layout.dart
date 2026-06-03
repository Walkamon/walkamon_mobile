import 'package:flutter/material.dart';

// TODO: replace with your actual BottomNavigation widget import
// import '../common/bottom_navigation.dart';

/// Equivalent of the React MainLayout component.
///
/// Full-screen column layout with a scrollable content area (Outlet)
/// and a persistent [BottomNavigation] pinned at the bottom.
///
/// Usage:
/// ```dart
/// MainLayout(child: HomeScreen())
/// ```
class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child});

  /// The active screen content — equivalent to <Outlet /> in React Router.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bg-transparent — inherit from RootLayout
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          // max-w-md ≈ 448px
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            children: [
              // flex-1 — expands to fill available space, clips overflow
              Expanded(
                child: ClipRect(
                  child: child,
                ),
              ),

              // <BottomNavigation /> pinned at bottom
              // TODO: uncomment when BottomNavigation is created
              // const BottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}
