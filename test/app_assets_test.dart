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

  test('PvP catalog has 17 icons, one HUD and 40 VFX frames', () async {
    expect(AppAssets.pvpCatalogAssets, hasLength(58));

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
}
