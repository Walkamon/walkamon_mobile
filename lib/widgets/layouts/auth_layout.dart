import 'package:flutter/material.dart';

/// Equivalent of the React AuthLayout component.
///
/// Provides a full-screen, scrollable, centered container
/// with consistent padding for auth screens. Use `CustomScrollView`
/// with `SliverFillRemaining` to ensure the child takes up at least
/// the screen height, solving infinite layout issues.
///
/// Usage:
/// ```dart
/// AuthLayout(child: LoginScreen())
/// ```
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  /// The screen content — equivalent to <Outlet /> in React Router.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: ScrollConfiguration(
              behavior: _HideScrollbarBehavior(),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: child,
                    ),
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

/// Hides the scrollbar — equivalent to Tailwind's `hide-scrollbars`.
class _HideScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
