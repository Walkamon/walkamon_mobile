import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_production_game.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

void main() {
  testWidgets('interrupted cached exit clip restarts and reaches hungry', (
    tester,
  ) async {
    PetProductionGame? game;

    Widget preview(String state) => MaterialApp(
      home: Center(
        child: SizedBox.square(
          dimension: 180,
          child: PetRuntimePreview(
            affinityCode: 'warm_sun',
            stageNo: 1,
            animationType: state,
            compact: true,
            onGameCreated: (created) => game = created,
          ),
        ),
      ),
    );

    Future<void> pumpUntil(
      bool Function(PetRuntimeDebugInfo info) ready,
    ) async {
      PetRuntimeDebugInfo? lastInfo;
      final timeout = Stopwatch()..start();
      while (timeout.elapsed < const Duration(seconds: 20)) {
        await tester.pump(const Duration(milliseconds: 10));
        final current = game;
        if (current != null) {
          lastInfo = current.currentDebugInfo;
          if (ready(lastInfo)) return;
          if (lastInfo.phase == 'load') {
            await tester.runAsync(current.images.ready);
          }
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 3)),
        );
      }
      fail(
        'Pet runtime did not reach the expected transition phase: '
        'state=${lastInfo?.state.wireName} phase=${lastInfo?.phase} '
        'clip=${lastInfo?.clipId} frame=${lastInfo?.frameIndex}',
      );
    }

    await tester.pumpWidget(preview('happy'));
    await pumpUntil(
      (info) => info.state == PetSemanticState.happy && info.phase == 'loop',
    );

    await tester.pumpWidget(preview('idle'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(preview('hungry'));
    await pumpUntil(
      (info) => info.state == PetSemanticState.hungry && info.phase == 'loop',
    );

    expect(game!.currentDebugInfo.clipId, contains('hungry_loop'));
    expect(tester.takeException(), isNull);
  });
}
