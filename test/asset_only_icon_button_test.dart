import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/widgets/common/asset_only_icon_button.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';

void main() {
  testWidgets('asset-only button has a transparent permanent surface', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetOnlyIconButton(
            semanticLabel: 'Settings',
            asset: AppAssets.iconSettingsNav,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(
      iconButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      Colors.transparent,
    );
    expect(iconButton.style?.elevation?.resolve(<WidgetState>{}), 0);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byType(AssetOnlyIconButton));
    expect(taps, 1);
  });

  testWidgets('shared game back control uses the asset-only presentation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameBackButton(semanticLabel: 'Back', onPressed: () {}),
        ),
      ),
    );

    expect(find.byType(AssetOnlyIconButton), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });
}
