import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/core/constants/app_audio_assets.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Auth sample assets are bundled', () async {
    for (final path in [
      AppAssets.authGarden,
      AppAssets.authLoginSteps,
      AppAssets.authMail,
      AppAssets.authLock,
      AppAssets.authVisibility,
      AppAssets.authVisibilityOff,
    ]) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('PvP catalog has icons, maps, HUD and VFX frames', () async {
    expect(AppAssets.pvpCatalogAssets, hasLength(68));

    for (final path in AppAssets.pvpCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Notification and feedback catalog assets are bundled', () async {
    expect(AppAssets.notificationCatalogAssets, hasLength(15));

    for (final path in AppAssets.notificationCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Mission frame assets are bundled', () async {
    for (final path in AppAssets.missionCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Canonical icon catalog is complete, unique and bundled', () async {
    expect(AppAssets.iconCatalogAssets, hasLength(136));
    expect(AppAssets.iconCatalogAssets.toSet(), hasLength(136));

    for (final path in AppAssets.iconCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Ambiguous legacy aliases retain their original semantics', () {
    expect(AppAssets.iconSteps, AppAssets.iconStep);
    expect(AppAssets.iconStepsNav, isNot(AppAssets.iconStep));
    expect(AppAssets.iconDailyReward, AppAssets.iconDailyRewardRes);
  });

  test(
    'Production pet manifest and representative sheets are bundled',
    () async {
      final manifest = await PetRuntimeManifestLoader().load();
      expect(manifest.forms, hasLength(7));
      for (final form in manifest.forms.values) {
        expect(form.states.keys.toSet(), containsAll(PetSemanticState.values));
        final idle = form.states[PetSemanticState.idle]!.loop!;
        final data = await rootBundle.load(idle.sheet);
        expect(data.lengthInBytes, greaterThan(0), reason: idle.sheet);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, idle.columns * manifest.runtimeSize);
        expect(frame.image.height, idle.rows * manifest.runtimeSize);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test('Home chrome icons and backgrounds are bundled', () async {
    expect(AppAssets.homeChromeAssets, hasLength(23));

    for (final path in AppAssets.homeChromeAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('App audio assets are bundled', () async {
    for (final path in [
      AppAudioAssets.homeMusic,
      AppAudioAssets.homeFeed,
      AppAudioAssets.homeLevelUp,
      AppAudioAssets.battleMusic,
      AppAudioAssets.reward,
      AppAudioAssets.tab,
      AppAudioAssets.useItem,
    ]) {
      final data = await rootBundle.load('assets/$path');
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
