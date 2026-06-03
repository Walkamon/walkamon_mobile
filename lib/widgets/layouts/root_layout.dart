import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Equivalent of the React RootLayout component.
///
/// Provides:
/// - Global background color (light: #f8fcfd / dark: darkBackground)
/// - Decorative tiled paw-print background texture (opacity ~2%)
/// - A global [MessengerKey] for toast-style snackbars (replaces Sonner)
/// - Wraps [child] — equivalent to <Outlet /> in React Router
///
/// Usage:
/// ```dart
/// // In MaterialApp:
/// builder: (context, child) => RootLayout(child: child!),
/// scaffoldMessengerKey: RootLayout.messengerKey,
/// ```
class RootLayout extends StatelessWidget {
  const RootLayout({super.key, required this.child});

  /// Drop-in replacement for Sonner's <Toaster />.
  /// Pass this to [MaterialApp.scaffoldMessengerKey] so any screen
  /// can call [RootLayout.showToast] from anywhere.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Show a toast message — equivalent to Sonner's `toast(message)`.
  static void showToast(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(
            // offset={240} in Sonner → push snackbar down from top
            top: 240,
            left: 16,
            right: 16,
          ),
          duration: duration,
        ),
      );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // bg-[#f8fcfd] dark:bg-slate-950
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF8FCFD);

    return Material(
      color: bgColor,
      child: Stack(
        children: [
          // ─── Global Background Texture ───────────────────────────────
          // fixed inset-0 pointer-events-none opacity-[0.02]
          const Positioned.fill(
            child: IgnorePointer(
              child: _PawPrintTexture(),
            ),
          ),

          // ─── Main Content (<Outlet />) ────────────────────────────────
          child,
        ],
      ),
    );
  }
}

// ── Paw-print tiled background ──────────────────────────────────────────────

class _PawPrintTexture extends StatelessWidget {
  const _PawPrintTexture();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // text-slate-900 dark:text-slate-300 @ opacity 0.02
    final color = (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A))
        .withValues(alpha: 0.02);

    // [...Array(30)].map — 30 paw prints arranged in a wrap
    return Opacity(
      opacity: 1, // colour already carries opacity above
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Wrap(
          spacing: 40,
          runSpacing: 40,
          alignment: WrapAlignment.spaceAround,
          children: List.generate(
            30,
            (_) => Transform.rotate(
              // rotate-45 scale-150
              angle: math.pi / 4,
              child: Transform.scale(
                scale: 1.5,
                child: _PawPrintIcon(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SVG paw print drawn with [CustomPainter] — equivalent to the inline SVG.
class _PawPrintIcon extends StatelessWidget {
  const _PawPrintIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _PawPrintPainter(color: color),
    );
  }
}

class _PawPrintPainter extends CustomPainter {
  const _PawPrintPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final sx = size.width / 24;
    final sy = size.height / 24;

    // Top-centre toe pad
    canvas.drawCircle(Offset(12 * sx, 6 * sy), 2.5 * sx, paint);
    // Left toe pad
    canvas.drawCircle(Offset(7 * sx, 7.5 * sy), 2.5 * sx, paint);
    // Right toe pad
    canvas.drawCircle(Offset(17 * sx, 7.5 * sy), 2.5 * sx, paint);

    // Main pad (ellipse)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(12 * sx, 16 * sy),
        width: 10 * sx,
        height: 8 * sy,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PawPrintPainter oldDelegate) =>
      oldDelegate.color != color;
}
