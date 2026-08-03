import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_atlas_grid_animation.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

void main() {
  testWidgets('recreates the atlas when the active pet form changes', (
    tester,
  ) async {
    Widget buildPreview(String affinityCode, int stageNo) {
      return MaterialApp(
        home: PetRuntimePreview(
          affinityCode: affinityCode,
          stageNo: stageNo,
          compact: true,
        ),
      );
    }

    await tester.pumpWidget(buildPreview('sprout', 0));
    await tester.pump();

    final atlasFinder = find.byType(PetAtlasGridAnimation);
    final sproutState = tester.state(atlasFinder);
    expect(
      tester.widget<PetAtlasGridAnimation>(atlasFinder).atlasAsset,
      AppAssets.sproutDefaultAtlas,
    );

    await tester.pumpWidget(buildPreview('dawn', 2));
    await tester.pump();

    expect(
      tester.widget<PetAtlasGridAnimation>(atlasFinder).atlasAsset,
      AppAssets.dawnStage2DefaultAtlas,
    );
    expect(tester.state(atlasFinder), isNot(same(sproutState)));
    expect(tester.takeException(), isNull);
  });
}
