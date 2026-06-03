import 'package:flutter/material.dart';

/// Equivalent of the React AuthLayout component.
///
/// Provides a full-screen, scrollable, centered column container
/// with consistent padding for auth screens.
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
      // bg-transparent — inherit scaffold background
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // max-w-md ≈ 448px
            constraints: const BoxConstraints(maxWidth: 448),
            child: ScrollConfiguration(
              // hide-scrollbars
              behavior: _HideScrollbarBehavior(),
              child: SingleChildScrollView(
                // px-6 py-10 → horizontal 24, vertical 40
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // min-h-[100dvh]
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [child],
                    ),
                  ),
                ),
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
  ) =>
      child;
}
