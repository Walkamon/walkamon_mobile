import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/screen/leaderboard/leaderboard_screen.dart';

void main() {
  testWidgets('Leaderboard screen renders filters and podium', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LeaderboardScreen()),
      ),
    );

    expect(find.text('Bảng xếp hạng'), findsOneWidget);
    expect(find.text('Toàn Cầu'), findsOneWidget);
    expect(find.text('Bước chân'), findsOneWidget);
  });
}
