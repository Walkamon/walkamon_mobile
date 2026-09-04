import 'package:flutter/material.dart';
import 'game_notice_host.dart';

export 'game_notice_host.dart' show GameNoticeRegion;

void showGameNotificationDialog(
  BuildContext context, {
  required String message,
  required bool isSuccess,
  bool isReward = false,
  GameNoticeRegion region = GameNoticeRegion.generic,
}) {
  // Keep this compatibility helper for existing screens, but route feedback
  // through the single root host instead of stacking transient dialogs.
  showGameNotice(
    message,
    type: isReward
        ? GameNoticeType.reward
        : isSuccess
        ? GameNoticeType.success
        : GameNoticeType.error,
    region: region,
  );
}
