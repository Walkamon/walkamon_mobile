import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'game_button_label.dart';

class GameDualBottomTabs extends StatelessWidget {
  const GameDualBottomTabs({
    super.key,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstSelected,
    required this.onFirstTap,
    required this.onSecondTap,
  });

  final String firstLabel;
  final String secondLabel;
  final bool firstSelected;
  final VoidCallback onFirstTap;
  final VoidCallback onSecondTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.darkNavigationActive : AppColors.buttonGreen;
    final textColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
    Widget tab(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? (isDark ? AppColors.darkBorder : AppColors.woodDeep) : Colors.transparent,
                  width: 1.7,
                ),
              ),
              child: selected
                  ? GameButtonLabel(
                      label,
                      fontSize: 13,
                      color: isDark ? AppColors.darkForeground : AppColors.buttonText,
                      outlineColor: isDark ? AppColors.darkBorder : AppColors.woodDeep,
                      outlineWidth: 2.5,
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard.withValues(alpha: 0.96) : AppColors.authCard.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.wood, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.woodDeep.withValues(alpha: 0.2),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            tab(firstLabel, firstSelected, onFirstTap),
            const SizedBox(width: 5),
            tab(secondLabel, !firstSelected, onSecondTap),
          ],
        ),
      ),
    );
  }
}
