import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/models/leaderboard_response.dart';
import 'package:walkamon_mobile/data/repositories/leaderboard_repository.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/leaderboard/leaderboard_screen.dart';

class _FakeLeaderboardRepository extends LeaderboardRepository {
  @override
  Future<ApiResponse<LeaderboardResponse>> getLeaderboard(String type) async {
    return ApiResponse<LeaderboardResponse>(
      success: true,
      status: 200,
      message: 'ok',
      data: LeaderboardResponse(
        type: type,
        fromDate: '2026-08-15',
        toDate: '2026-08-15',
        myRank: 0,
        leaderboard: const [],
      ),
    );
  }
}

void main() {
  testWidgets('Leaderboard screen renders filters and podium', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LeaderboardScreen(repository: _FakeLeaderboardRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bảng xếp hạng'), findsWidgets);
    expect(find.text('Hôm nay'), findsWidgets);
    expect(find.text('Bước chân'), findsWidgets);
  });
}
