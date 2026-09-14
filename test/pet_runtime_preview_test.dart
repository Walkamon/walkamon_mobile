import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_production_game.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_renderer_host.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

void main() {
  testWidgets(
    'hidden and background pet engine pauses without replacing its owner',
    (tester) async {
      PetProductionGame? game;
      var enabled = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return TickerMode(
                enabled: enabled,
                child: PetRuntimePreview(
                  compact: true,
                  onGameCreated: (value) => game = value,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      final original = game;
      update(() => enabled = false);
      await tester.pump();
      expect(game!.paused, isTrue);
      update(() => enabled = true);
      await tester.pump();
      expect(game!.paused, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(game!.paused, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(game!.paused, isFalse);
      expect(game, same(original));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('keeps one Flame game while form and semantic state change', (
    tester,
  ) async {
    PetProductionGame? createdGame;
    var creationCount = 0;
    Widget buildPreview(
      String affinityCode,
      int stageNo,
      String animationType,
    ) {
      return MaterialApp(
        home: PetRuntimePreview(
          affinityCode: affinityCode,
          stageNo: stageNo,
          animationType: animationType,
          compact: true,
          onGameCreated: (game) {
            createdGame = game;
            creationCount++;
          },
        ),
      );
    }

    await tester.pumpWidget(buildPreview('sprout', 0, 'idle'));
    await tester.pump();
    final firstGame = createdGame;
    expect(firstGame, isNotNull);
    expect(creationCount, 1);
    expect(find.byType(PetRendererHost), findsOneWidget);

    await tester.pumpWidget(buildPreview('dawn', 2, 'sad'));
    await tester.pump();

    expect(createdGame, same(firstGame));
    expect(creationCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Flame canvas does not consume the outer pet tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GestureDetector(
            key: const ValueKey('outer-pet-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const PetRuntimePreview(compact: true),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('outer-pet-tap')));
    await tester.pump();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  test('normalizes semantic names and legacy form identity', () {
    expect(PetSemanticState.fromWire('hunggry'), PetSemanticState.hungry);
    expect(PetSemanticState.fromWire('unknown'), PetSemanticState.idle);
    expect(resolvePetRuntimeFormKey('Mầm Non', 1), 'sprout_stage0');
    expect(resolvePetRuntimeFormKey('Ánh Trăng', 99), 'moonlight_stage2');
  });
}
