import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A compact, non-modal tutorial tip used while time-sensitive gameplay keeps
/// running. Only the card itself receives input; the race and item HUD remain
/// fully interactive around it.
class TutorialContextTip extends StatelessWidget {
  const TutorialContextTip({
    super.key,
    required this.title,
    required this.description,
    required this.stepLabel,
    required this.actionLabel,
    required this.skipLabel,
    required this.onAction,
    required this.onSkip,
    this.alignment = Alignment.topCenter,
    this.margin = const EdgeInsets.fromLTRB(64, 78, 64, 0),
  });

  final String title;
  final String description;
  final String stepLabel;
  final String actionLabel;
  final String skipLabel;
  final FutureOr<void> Function() onAction;
  final FutureOr<void> Function() onSkip;
  final Alignment alignment;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: alignment,
          child: SafeArea(
            child: Container(
              margin: margin,
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 9),
              decoration: BoxDecoration(
                color: AppColors.authCard.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.woodDeep.withValues(alpha: .72),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$stepLabel · $title',
                          style: const TextStyle(
                            color: AppColors.woodDeep,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          description,
                          style: const TextStyle(
                            color: AppColors.inkBrown,
                            fontSize: 11.5,
                            height: 1.28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: () => onAction(),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: AppColors.buttonGreen,
                            foregroundColor: AppColors.woodDeep,
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(fontFamily: 'Quicksand'),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: TextButton(
                          onPressed: () => onSkip(),
                          child: Text(
                            skipLabel,
                            style: const TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    ],
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
