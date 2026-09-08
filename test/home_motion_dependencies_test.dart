import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/screen/home/home_screen.dart';
import 'package:walkamon_mobile/widgets/motion/animated_game_value.dart';

void main() {
  test('Home entry point compiles with its tracked dependencies', () {
    expect(const HomeScreen(title: 'Home'), isA<StatefulWidget>());
  });

  testWidgets('counter uses first value as baseline and animates updates', (
    tester,
  ) async {
    var value = 10;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return AnimatedGameCounter(value: value);
          },
        ),
      ),
    );
    expect(find.text('10'), findsOneWidget);
    update(() => value = 20);
    await tester.pump();
    expect(find.text('10'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('reduced motion updates immediately', (tester) async {
    var value = 10;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (_, setState) {
              update = setState;
              return AnimatedGameCounter(value: value);
            },
          ),
        ),
      ),
    );
    update(() => value = 20);
    await tester.pump();
    expect(find.text('20'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });
}
