import 'package:flutter/services.dart';

/// Centralized, optional tactile feedback for discrete game events.
///
/// Keeping haptics behind one service prevents widgets from vibrating after
/// the player disables the setting and makes the feedback vocabulary
/// consistent across Home, rewards and PvP.
abstract final class AppHaptics {
  static bool _enabled = true;

  static bool get enabled => _enabled;

  static void setEnabled(bool enabled) => _enabled = enabled;

  static Future<void> selection() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> lightImpact() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumImpact() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> warning() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }
}
