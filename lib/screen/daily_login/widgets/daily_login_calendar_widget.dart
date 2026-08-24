import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/daily_login_model.dart';

class DailyLoginCalendarWidget extends StatelessWidget {
  final List<DailyLoginRewardModel> rewards;
  final int currentDay;

  const DailyLoginCalendarWidget({
    Key? key,
    required this.rewards,
    required this.currentDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (rewards.isEmpty) {
      return Center(child: Text(l10n.dailyLoginNoRewardData));
    }

    // Chia danh sách làm 2 dòng giống TSX (4 ngày đầu, 3 ngày sau)
    final row1 = rewards.take(4).toList();
    final row2 = rewards.skip(4).take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final firstRowCardWidth = (constraints.maxWidth - 30) / 4;
        final cardHeight = (firstRowCardWidth * 1.16).clamp(82.0, 104.0);

        Widget rewardRow(List<DailyLoginRewardModel> items) {
          return SizedBox(
            height: cardHeight,
            child: Row(
              children: items.map((reward) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _RewardCard(rewardInfo: reward),
                  ),
                );
              }).toList(),
            ),
          );
        }

        return Column(
          children: [
            rewardRow(row1),
            const SizedBox(height: 10),
            FractionallySizedBox(widthFactor: 0.75, child: rewardRow(row2)),
          ],
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  final DailyLoginRewardModel rewardInfo;

  const _RewardCard({required this.rewardInfo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isClaimed = rewardInfo.status == 'claimed';
    final isCurrent = rewardInfo.status == 'claimable';
    final isSpecial = rewardInfo.day == 7;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Thiết lập phong cách (Style) theo trạng thái
    Color bgColor;
    Color borderColor;
    Color textDayColor;
    Color textAmountColor;
    Widget iconWidget;
    double scale = isCurrent ? 1.025 : 1.0;
    double borderWidth = isCurrent || isSpecial ? 2.2 : 1.5;

    if (isClaimed) {
      bgColor = isDark
          ? AppColors.darkMuted
          : AppColors.panelMuted.withValues(alpha: 0.82);
      borderColor = isDark ? AppColors.darkCardBorder : AppColors.wood;
      textDayColor = isDark
          ? AppColors.darkMutedForeground
          : AppColors.outlineBrown;
      textAmountColor = isDark
          ? AppColors.darkMutedForeground
          : AppColors.outlineBrown;
      iconWidget = Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.leaf,
          shape: BoxShape.circle,
        ),
        child: const AppIcon(
          Icons.check_rounded,
          size: 24,
          color: Colors.white,
        ),
      );
    } else if (isCurrent) {
      bgColor = isDark
          ? AppColors.darkPrimary
          : AppColors.authCard.withValues(alpha: 0.94);
      borderColor = isDark ? AppColors.darkCardBorder : AppColors.woodDeep;
      textDayColor = isDark ? AppColors.darkForeground : AppColors.oliveDeep;
      textAmountColor = isDark ? AppColors.darkForeground : AppColors.inkDark;
      iconWidget = Image.asset(
        AppAssets.iconDewDrop,
        width: 42,
        height: 42,
        fit: BoxFit.contain,
      );
    } else if (isSpecial) {
      bgColor = isDark
          ? AppColors.darkNestedCard
          : AppColors.creamLight.withValues(alpha: 0.95);
      borderColor = isDark ? AppColors.darkCardBorder : AppColors.woodDeep;
      textDayColor = isDark ? AppColors.darkForeground : AppColors.woodDeep;
      textAmountColor = isDark ? AppColors.darkForeground : AppColors.inkBrown;
      iconWidget = Image.asset(
        AppAssets.iconDailyRewardRes,
        width: 46,
        height: 46,
        fit: BoxFit.contain,
      );
    } else {
      bgColor = isDark
          ? AppColors.darkNestedCard
          : AppColors.authCard.withValues(alpha: 0.9);
      borderColor = isDark ? AppColors.darkCardBorder : AppColors.wood;
      textDayColor = isDark
          ? AppColors.darkMutedForeground
          : AppColors.outlineBrown;
      textAmountColor = isDark ? AppColors.darkForeground : AppColors.inkDark;
      iconWidget = Opacity(
        opacity: 0.72,
        child: Image.asset(
          AppAssets.iconDewDrop,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      );
    }

    return Transform.scale(
      scale: scale,
      child: SizedBox.expand(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.woodDeep.withValues(alpha: 0.16),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : (isClaimed
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.woodDeep.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.dayLabel(rewardInfo.day),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: textDayColor,
                ),
              ),
              const Spacer(),
              iconWidget,
              const Spacer(),
              Text(
                l10n.rewardCount(
                  isSpecial && !isClaimed ? 1 : rewardInfo.reward,
                ),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: textAmountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
