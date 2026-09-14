import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production manifest has exact semantic coverage for all seven forms',
    () async {
      final manifest = await PetRuntimeManifestLoader().load();
      expect(manifest.forms, hasLength(7));
      expect(manifest.runtimeSize, 384);
      expect(manifest.baselineNormalized, closeTo(380 / 384, 0.000001));

      for (final form in manifest.forms.values) {
        expect(form.states.keys.toSet(), containsAll(PetSemanticState.values));
        expect(form.states[PetSemanticState.idle]!.loop, isNotNull);
        expect(form.states[PetSemanticState.hungry]!.enter, isNotNull);
        expect(form.states[PetSemanticState.hungry]!.loop, isNotNull);
        for (final state in [
          PetSemanticState.sad,
          PetSemanticState.sleep,
          PetSemanticState.excited,
        ]) {
          final definition = form.states[state]!;
          expect(
            definition.enter,
            isNotNull,
            reason: '${form.key}/$state enter',
          );
          expect(definition.loop, isNotNull, reason: '${form.key}/$state loop');
          expect(definition.exit, isNotNull, reason: '${form.key}/$state exit');
        }
        final feed = form.states[PetSemanticState.feedEat]!.action;
        final hello = form.states[PetSemanticState.tapHello]!.action;
        expect(feed, hasLength(4));
        expect(hello, hasLength(1));
        expect(hello.single.totalDuration, greaterThanOrEqualTo(2));
        expect(
          hello.single.sheet,
          isNot(form.states[PetSemanticState.happy]!.loop!.sheet),
        );
        expect(
          feed.map((clip) => clip.sheet),
          isNot(contains(form.states[PetSemanticState.hungry]!.loop!.sheet)),
        );
      }
    },
  );

  test('missing semantic state falls back only to neutral idle', () {
    const idleClip = PetRuntimeClip(
      id: 'idle',
      sheet: 'idle.webp',
      columns: 1,
      rows: 1,
      frameCount: 1,
      durations: [0.2],
      loop: true,
    );
    const form = PetRuntimeFormDefinition(
      key: 'test',
      motionMode: PetMotionMode.ground,
      homeCanvasScale: 1,
      states: {
        PetSemanticState.idle: PetRuntimeStateDefinition(loop: idleClip),
      },
    );

    expect(form.stateOrIdle(PetSemanticState.excited).loop, same(idleClip));
  });

  test('Warm Sun stage 2 Hello keeps the reviewed four-limb repair', () async {
    final sheet = File(
      'assets/Mobile/pet_runtime_prod_v1/warm_sun_stage2/'
      'tap_hello_action_0_tap_hello.webp',
    );

    expect(sheet.existsSync(), isTrue);
    expect(
      sha256.convert(await sheet.readAsBytes()).toString(),
      '53a9a5ec956ea3442e9736ad46b392eb30f5633af299a6b7eff0da36a48171e2',
      reason:
          'This sheet is locked after visual review: the raised front-left '
          'foreleg no longer has a duplicate planted copy at the Hello peak. '
          'Repack only after a new anatomy review.',
    );
  });

  test('invalid clip timing is rejected at manifest boundary', () {
    expect(
      () => PetRuntimeClip.fromJson({
        'id': 'bad',
        'sheet': 'bad.webp',
        'columns': 1,
        'rows': 1,
        'frameCount': 2,
        'durations': [0.1],
      }),
      throwsFormatException,
    );
  });
}
