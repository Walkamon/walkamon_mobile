import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_icon.dart';
import 'game_button_label.dart';

Future<bool> showGameConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool destructive = false,
  IconData icon = Icons.warning_amber_rounded,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final background = isDark ? AppColors.darkCard : AppColors.authCard;
      final foreground = isDark ? AppColors.darkForeground : AppColors.woodDeep;
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.wood,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  icon,
                  size: 50,
                  color: destructive ? AppColors.danger : foreground,
                ),
                const SizedBox(height: 10),
                GameButtonLabel(
                  title,
                  fontSize: 21,
                  color: foreground,
                  outlineColor: background,
                  outlineWidth: 3,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: destructive
                              ? AppColors.danger
                              : AppColors.buttonGreen,
                          foregroundColor: AppColors.buttonText,
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result ?? false;
}
