import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/screen/debug/pet_animation_player_screen.dart';

void main() {
  test(
    'PLAY ALL hello hold follows the real clip instead of the old 5.6 s',
    () {
      expect(petAnimationPlayerHelloHold, const Duration(milliseconds: 2700));
    },
  );

  testWidgets('PLAY ALL is interactive and can be stopped', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PetAnimationPlayerScreen()),
    );
    await tester.pump();

    final playAll = find.byKey(const ValueKey('pet-player-play-all'));
    expect(playAll, findsOneWidget);
    expect(find.text('PHÁT TẤT CẢ'), findsOneWidget);

    await tester.tap(playAll);
    await tester.pump();
    expect(find.text('DỪNG'), findsOneWidget);

    await tester.tap(playAll);
    await tester.pump();
    expect(find.text('PHÁT TẤT CẢ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
