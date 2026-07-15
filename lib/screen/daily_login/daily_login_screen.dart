import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/daily_login_provider.dart';
import 'widgets/daily_login_calendar_widget.dart';

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
                  'Lỗi: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final data = provider.calendarData;
            if (data == null) {
              return const Center(child: Text('Không có dữ liệu điểm danh.'));
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
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Text(
                        'Điểm Danh',
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
                      child: Icon(
                        Icons.card_giftcard,
                        size: 44,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quà Hàng Ngày',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A5D4E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Đăng nhập mỗi ngày để nhận quà hấp dẫn.\nĐừng bỏ lỡ ngày thứ 7 nhé!',
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
                        onPressed: (!data.canClaimToday || provider.isLoading)
                            ? null
                            : () async {
                                final success = await provider.claimReward();
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nhận thưởng thành công!'),
                                    ),
                                  );
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
                                    ? 'Đã Nhận Hôm Nay'
                                    : 'Nhận Quà Ngay',
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
