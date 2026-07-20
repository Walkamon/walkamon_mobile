import 'package:flutter/material.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
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

    return Column(
      children: [
        // Hàng 1 (Ngày 1 - 4)
        Row(
          children: row1.map((reward) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: _RewardCard(rewardInfo: reward),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Hàng 2 (Ngày 5 - 7)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: row2.map((reward) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: _RewardCard(rewardInfo: reward),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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

    // Thiết lập phong cách (Style) theo trạng thái
    Color bgColor;
    Color borderColor;
    Color textDayColor;
    Color textAmountColor;
    Widget iconWidget;
    double scale = isCurrent ? 1.02 : 1.0;
    double borderWidth = isCurrent || isSpecial ? 2.0 : 1.0;

    if (isClaimed) {
      bgColor = const Color(0xFFE2E8DF).withOpacity(0.8);
      borderColor = const Color(0xFFCBD5C8);
      textDayColor = const Color(0xFF8A9A8D);
      textAmountColor = const Color(0xFF8A9A8D);
      iconWidget = Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Color(0xFF8A9A8D),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 18, color: Colors.white),
      );
    } else if (isCurrent) {
      bgColor = Theme.of(context).cardColor;
      borderColor = const Color(0xFF7A9D84);
      textDayColor = const Color(0xFF7A9D84);
      textAmountColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
      iconWidget = const Icon(
        Icons.water_drop,
        size: 28,
        color: Color(0xFF7A9D84),
      );
    } else if (isSpecial) {
      bgColor = const Color(0xFFFFF4C2);
      borderColor = const Color(0xFFFFE885);
      textDayColor = const Color(0xFF8A9A8D);
      textAmountColor = const Color(0xFFD97706);
      iconWidget = const Icon(
        Icons.card_giftcard,
        size: 28,
        color: Color(0xFFF59E0B),
      );
    } else {
      bgColor = Theme.of(context).cardColor;
      borderColor = Colors.grey.shade300;
      textDayColor = Colors.grey.shade500;
      textAmountColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
      iconWidget = const Icon(
        Icons.water_drop,
        size: 28,
        color: Color(0xFFA2B2A6),
      );
    }

    return Transform.scale(
      scale: scale,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (isClaimed
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
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
                  fontSize: 10,
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
                  fontSize: 13,
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
