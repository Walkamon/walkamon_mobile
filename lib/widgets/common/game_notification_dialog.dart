import 'package:flutter/material.dart';

import 'app_icon.dart';

void showGameNotificationDialog(
  BuildContext context, {
  required String message,
  required bool isSuccess,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!dialogContext.mounted) return;

        final navigator = Navigator.of(dialogContext, rootNavigator: true);
        final isCurrentRoute = ModalRoute.of(dialogContext)?.isCurrent ?? false;
        if (isCurrentRoute && navigator.canPop()) {
          navigator.pop();
        }
      });

      final colorScheme = Theme.of(context).colorScheme;
      final backgroundColor = isSuccess
          ? colorScheme.primary
          : colorScheme.error;
      final contentColor = isSuccess
          ? colorScheme.onPrimary
          : colorScheme.onError;

      return Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: contentColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  isSuccess
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: contentColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    color: contentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
