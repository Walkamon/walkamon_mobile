import 'dart:async';

import 'package:flutter/material.dart';

import 'app_icon.dart';
import '../../core/theme/app_colors.dart';
import '../../core/feedback/app_haptics.dart';

void showGameNotificationDialog(
  BuildContext context, {
  required String message,
  required bool isSuccess,
}) {
  if (isSuccess) {
    unawaited(AppHaptics.success());
  } else {
    unawaited(AppHaptics.warning());
  }
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (dialogContext) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (!dialogContext.mounted) return;

        final navigator = Navigator.of(dialogContext, rootNavigator: true);
        final isCurrentRoute = ModalRoute.of(dialogContext)?.isCurrent ?? false;
        if (isCurrentRoute && navigator.canPop()) {
          navigator.pop();
        }
      });

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final backgroundColor = isSuccess
          ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
          : (isDark ? AppColors.darkAccent : AppColors.danger);
      final contentColor = isDark
          ? AppColors.darkForeground
          : AppColors.buttonText;

      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 11, 16, 11),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        isSuccess
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: contentColor,
                        size: 34,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: contentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
