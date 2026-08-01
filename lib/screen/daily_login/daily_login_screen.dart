import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import '../../providers/daily_login_provider.dart';
import 'widgets/daily_login_calendar_widget.dart';
import 'package:walkamon_mobile/data/models/daily_login_model.dart';

class DailyLoginScreen extends StatefulWidget {
  const DailyLoginScreen({super.key});

  @override
  State<DailyLoginScreen> createState() => _DailyLoginScreenState();
}

class _DailyLoginScreenState extends State<DailyLoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyLoginProvider>().loadDailyLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<DailyLoginProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.calendarData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null &&
                provider.calendarData == null) {
              return Center(
                child: Text(
                  '${l10n.errorPrefix}: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final data = provider.calendarData;
            if (data == null) {
              return Center(child: Text(l10n.dailyLoginNoData));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Custom Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const AppIcon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        l10n.dailyLoginTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A5D4E),
                        ),
                      ),
                      const SizedBox(
                        width: 40,
                      ), // Cân bằng không gian với nút back
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Main Gift Icon & Text
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4C2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFE885),
                        width: 4,
                      ),
                    ),
                    child: const Center(
                      child: AppIcon(
                        Icons.card_giftcard,
                        size: 44,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.dailyLoginRewardTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A5D4E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.dailyLoginRewardSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Lưới Lịch điểm danh (Calendar)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: DailyLoginCalendarWidget(
                        rewards: data.rewards,
                        currentDay: data.currentDay,
                      ),
                    ),
                  ),

                  // Claim Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                if (!data.canClaimToday) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.dailyLoginAlreadyClaimed,
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // Xác định rõ kiểu dữ liệu trả về để compiler không nhận nhầm thành bool
                                final ClaimDailyRewardData? result =
                                    await provider.claimReward();

                                if (result != null && mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.dailyLoginSuccessTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          '${l10n.dailyLoginSuccessMessage(result.claimedDay)}\n\n'
                                          '${l10n.dailyLoginSuccessReward(result.reward)}\n'
                                          '${l10n.dailyLoginSuccessBalance(result.balance)}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text(
                                              l10n.dailyLoginSuccessAction,
                                              style: const TextStyle(
                                                color: Color(0xFF7A9D84),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  if (mounted &&
                                      provider.errorMessage != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${l10n.errorPrefix}: ${provider.errorMessage}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !data.canClaimToday
                              ? const Color(0xFFB0C0B4)
                              : const Color(0xFF7A9D84),
                          disabledBackgroundColor: const Color(0xFFB0C0B4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: !data.canClaimToday ? 0 : 2,
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                !data.canClaimToday
                                    ? l10n.dailyLoginClaimedToday
                                    : l10n.dailyLoginClaimNow,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
