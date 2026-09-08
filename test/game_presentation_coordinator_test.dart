import 'package:flutter/material.dart';
import 'package:walkamon_mobile/widgets/motion/nine_slice_game_frame.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/motion/game_presentation_coordinator.dart';
import 'package:walkamon_mobile/widgets/motion/game_presentation_host.dart';

void main() {
  testWidgets('reward slice stays inside the scaled source and clears crest', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GameRewardOverlay(
              reward: const GameRewardPresentation(
                id: 'layout',
                message: 'Received 50',
                items: [GameRewardEntry(name: 'Wind Charm', quantity: 2)],
              ),
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final panel = find.byType(NineSliceGameFrame);
    final frame = tester.widget<NineSliceGameFrame>(panel);
    expect(frame.slice.right, lessThanOrEqualTo(768));
    expect(frame.slice.bottom, lessThanOrEqualTo(768));
    expect(frame.slice.top, 320);
    expect(
      tester.getTopLeft(find.text('Received 50')).dy -
          tester.getTopLeft(panel).dy,
      greaterThanOrEqualTo(72),
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'only one major presentation; duplicate ids stay suppressed until logout',
    () {
      final coordinator = GamePresentationCoordinator();
      expect(coordinator.begin('claim:1'), isTrue);
      expect(coordinator.begin('claim:2'), isFalse);
      coordinator.finish();
      expect(coordinator.begin('claim:1'), isFalse);
      expect(coordinator.begin('claim:2'), isTrue);
      coordinator.reset();
      expect(coordinator.begin('claim:1'), isTrue);
    },
  );

  testWidgets(
    'reward renders actual entries and disappears on account change',
    (tester) async {
      var account = 'one';
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return GamePresentationHost(
                sessionKey: account,
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => GamePresentationHost.showReward(
                      context,
                      const GameRewardPresentation(
                        id: 'claim:1',
                        message: 'Received 50',
                        items: [
                          GameRewardEntry(name: 'Wind Charm', quantity: 2),
                        ],
                      ),
                    ),
                    child: const Text('Claim'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Claim'));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Wind Charm ×2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      update(() => account = 'two');
      await tester.pump();
      expect(find.byType(GameRewardOverlay), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
