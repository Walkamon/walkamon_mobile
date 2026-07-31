import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';

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
    expect(AppAssets.pvpCatalogAssets, hasLength(64));

    for (final path in AppAssets.pvpCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Notification and feedback catalog assets are bundled', () async {
    expect(AppAssets.notificationCatalogAssets, hasLength(13));

    for (final path in AppAssets.notificationCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Pet runtime assets are bundled', () async {
    expect(AppAssets.petRuntimeCatalogAssets, hasLength(16));

    for (final path in AppAssets.petRuntimeCatalogAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  test('Home chrome icons and backgrounds are bundled', () async {
    expect(AppAssets.homeChromeAssets, hasLength(19));

    for (final path in AppAssets.homeChromeAssets) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
