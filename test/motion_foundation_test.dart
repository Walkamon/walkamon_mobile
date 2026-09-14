import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/widgets/motion/animated_game_value.dart';
import 'package:walkamon_mobile/widgets/motion/walkamon_pressable.dart';
import 'package:walkamon_mobile/core/motion/motion_tokens.dart';
import 'package:walkamon_mobile/screen/home/home_pet_ambient.dart';

void main() {
  testWidgets(
    'first snapshot is baseline; updates retarget from rendered value',
    (tester) async {
      var target = 100.0;
      var drawn = -1.0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AnimatedGameValue(
                value: target,
                builder: (_, value) {
                  drawn = value;
                  return Text('$value');
                },
              );
            },
          ),
        ),
      );
      expect(drawn, 100);
      update(() => target = 200);
      await tester.pump();
      expect(drawn, 100);
      await tester.pump(const Duration(milliseconds: 100));
      final mid = drawn;
      expect(mid, inExclusiveRange(100, 200));
      update(() => target = 400);
      await tester.pump();
      expect(drawn, closeTo(mid, 0.001));
      await tester.pumpAndSettle();
      expect(drawn, 400);
      update(() => target = 80);
      await tester.pumpAndSettle();
      expect(drawn, 80);
    },
  );

  testWidgets(
    'reduced motion snaps values and preserves semantic true target',
    (tester) async {
      var target = 10;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return AnimatedGameCounter(value: target);
              },
            ),
          ),
        ),
      );
      update(() => target = 500);
      await tester.pump();
      expect(find.text('500'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('background finishes interpolation without replay on resume', (
    tester,
  ) async {
    var target = 10.0;
    var drawn = 0.0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AnimatedGameValue(
              value: target,
              builder: (_, value) {
                drawn = value;
                return const SizedBox();
              },
            );
          },
        ),
      ),
    );
    update(() => target = 100);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(drawn, 100);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(drawn, 100);
  });

  testWidgets('press feedback does not delay or duplicate button action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: WalkamonPressable(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Feed'),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Feed')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .97);
    await gesture.up();
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  test('ambient never simulates a bond-producing action', () {
    for (var i = 0; i < 30; i++) {
      final cue = selectHomePetAmbientCue(
        energy: 100,
        energyMax: 100,
        lifeForce: 100,
        lifeForceMax: 100,
        bond: 50,
        bondMax: 100,
        hour: 12,
        cycle: i,
      );
      expect(cue?.animation, isNot('tap_hello'));
    }
  });

  test('VFX budgets honor quality and accessibility', () {
    expect(const MotionPolicy().particleBudget, 64);
    expect(const MotionPolicy(quality: VfxQuality.low).particleBudget, 24);
    expect(const MotionPolicy(quality: VfxQuality.high).particleBudget, 96);
    expect(const MotionPolicy(reduced: true).particleBudget, 0);
  });
}
