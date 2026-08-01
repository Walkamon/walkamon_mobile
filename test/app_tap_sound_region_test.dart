import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/audio/app_audio_service.dart';
import 'package:walkamon_mobile/core/audio/app_tap_sound_region.dart';

void main() {
  testWidgets('plays one tab sound for a tappable control', (tester) async {
    var playCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppTapSoundRegion(
          onTabSound: () => playCount++,
          child: Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: () {}, child: const Text('Tap')),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pump();

    expect(playCount, 1);
  });

  testWidgets('does not play a tab sound for non-tappable content', (
    tester,
  ) async {
    var playCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppTapSoundRegion(
          onTabSound: () => playCount++,
          child: const Scaffold(body: Center(child: Text('Plain text'))),
        ),
      ),
    );

    await tester.tap(find.text('Plain text'));
    await tester.pump();

    expect(playCount, 0);
  });

  testWidgets('does not overlap a control-specific sound', (tester) async {
    var playCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppTapSoundRegion(
          onTabSound: () => playCount++,
          child: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: AppAudioService.instance.suppressNextTabSound,
                child: const Text('Custom sound'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Custom sound'));
    await tester.pump();

    expect(playCount, 0);
  });
}
