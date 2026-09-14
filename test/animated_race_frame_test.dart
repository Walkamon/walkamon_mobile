import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/widgets/motion/animated_race_frame.dart';

void main() {
  testWidgets('reduced motion snaps without a cosmetic interpolation ticker', (
    tester,
  ) async {
    var target = const RaceFrame(0, 0, 0);
    late StateSetter update;
    late RaceFrame drawn;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AnimatedRaceFrame(
                target: target,
                builder: (_, frame) {
                  drawn = frame;
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      ),
    );
    update(() => target = const RaceFrame(.5, 50, 40));
    await tester.pump();
    expect(drawn.sameAs(target), isTrue);
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('camera and runners move together without extrapolation', (
    tester,
  ) async {
    var target = const RaceFrame(0, 0, 0);
    late StateSetter update;
    late RaceFrame drawn;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return AnimatedRaceFrame(
              target: target,
              builder: (_, frame) {
                drawn = frame;
                return const SizedBox();
              },
            );
          },
        ),
      ),
    );
    update(() => target = const RaceFrame(.5, 50, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(drawn.track, .25);
    expect(drawn.mine, 25);
    expect(drawn.opponent, 20);
    await tester.pump(const Duration(milliseconds: 25));
    expect(drawn.sameAs(target), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(drawn.sameAs(target), isTrue);
  });

  testWidgets(
    'new snapshot retargets and paused captures snap deterministically',
    (tester) async {
      var target = const RaceFrame(0, 0, 0);
      var snap = false;
      late StateSetter update;
      late RaceFrame drawn;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AnimatedRaceFrame(
                target: target,
                snap: snap,
                builder: (_, frame) {
                  drawn = frame;
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      );
      update(() => target = const RaceFrame(1, 100, 90));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final previous = drawn;
      update(() => target = const RaceFrame(1, 98, 88));
      await tester.pump();
      expect(drawn.sameAs(previous), isTrue);
      update(() => snap = true);
      await tester.pump();
      expect(drawn.sameAs(target), isTrue);
    },
  );
}
