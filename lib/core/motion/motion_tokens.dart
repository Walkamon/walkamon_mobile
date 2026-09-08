import 'package:flutter/material.dart';

/// Presentation timing only. Never use these durations to schedule API work.
abstract final class MotionTokens {
  static const press = Duration(milliseconds: 100);
  static const release = Duration(milliseconds: 140);
  static const noticeIn = Duration(milliseconds: 180);
  static const noticeOut = Duration(milliseconds: 140);
  static const card = Duration(milliseconds: 220);
  static const tab = Duration(milliseconds: 240);
  static const detail = Duration(milliseconds: 300);
  static const modal = Duration(milliseconds: 240);
  static const counter = Duration(milliseconds: 500);
  static const reward = Duration(milliseconds: 950);
  static const levelUp = Duration(milliseconds: 1500);
  static const evolution = Duration(milliseconds: 3600);
  static const reduced = Duration(milliseconds: 120);
  static const enterCurve = Curves.easeOutCubic;
  static const settleCurve = Curves.easeOutQuart;
}

enum VfxQuality { low, medium, high }

/// Derived from the platform; it does not change gameplay or step collection.
class MotionPolicy {
  const MotionPolicy({this.reduced = false, this.quality = VfxQuality.medium});

  final bool reduced;
  final VfxQuality quality;

  static MotionPolicy of(BuildContext context) => MotionPolicy(
    reduced:
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context),
  );

  Duration duration(Duration full) => reduced ? MotionTokens.reduced : full;
  int get particleBudget => reduced
      ? 0
      : switch (quality) {
          VfxQuality.low => 24,
          VfxQuality.medium => 64,
          VfxQuality.high => 96,
        };
}
