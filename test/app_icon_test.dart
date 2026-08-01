import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';

void main() {
  testWidgets('uses Walkamon artwork for a mapped Material icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppIcon(Icons.arrow_back, size: 32)),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 32);
    expect(image.height, 32);
    expect((image.image as AssetImage).assetName, AppAssets.iconBack);
  });

  testWidgets('falls back to Flutter Icon when no artwork is mapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppIcon(Icons.radio_button_unchecked)),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('can keep a mapped icon as a structural Flutter glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppIcon(Icons.check, useAsset: false)),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
  });
}
