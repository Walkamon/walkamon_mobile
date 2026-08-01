import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/pvp_asset_resolver.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/widgets/pvp_frame_animation.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/widgets/pvp_racing_environment.dart';

void main() {
  group('PvP three-map track geometry', () {
    test('selects each map at the documented phase boundary', () {
      expect(pvpTrackPhaseIndex(0), 0);
      expect(pvpTrackPhaseIndex((5 / 30) - 0.001), 0);
      expect(pvpTrackPhaseIndex(5 / 30), 1);
      expect(pvpTrackPhaseIndex((25 / 30) - 0.001), 1);
      expect(pvpTrackPhaseIndex(25 / 30), 2);
      expect(pvpTrackPhaseIndex(1), 2);
    });

    test('pet baselines match the two lanes in the asset guide', () {
      expect(pvpLaneBaseline(1000, 0), 580);
      expect(pvpLaneBaseline(1000, 1), 730);
    });

    test('pet movement stays inside safe horizontal bounds', () {
      const width = 400.0;
      const runnerWidth = 108.0;

      final start = pvpRunnerScreenX(
        viewportWidth: width,
        progress: -10,
        runnerWidth: runnerWidth,
      );
      final finish = pvpRunnerScreenX(
        viewportWidth: width,
        progress: 120,
        runnerWidth: runnerWidth,
      );

      expect(start - runnerWidth / 2, greaterThanOrEqualTo(8));
      expect(finish + runnerWidth / 2, lessThanOrEqualTo(width - 8));
    });
  });

  group('PvP asset resolution', () {
    test('returns start, loop and finish maps in order', () {
      expect(PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12)), [
        AppAssets.pvpMapMorningStart,
        AppAssets.pvpMapMorningLoop,
        AppAssets.pvpMapMorningFinish,
      ]);
      expect(PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 22)), [
        AppAssets.pvpMapNightStart,
        AppAssets.pvpMapNightLoop,
        AppAssets.pvpMapNightFinish,
      ]);
    });

    test('uses exact case-sensitive pet race paths', () {
      expect(
        PvpAssetResolver.petAnimationFrames(
          affinityCode: 'moonlight',
          stageNo: 2,
        ).first,
        'assets/Mobile/TInh Linh Ánh Trăng/stage2/pvp/race/race_F01.png',
      );
      expect(
        PvpAssetResolver.petAnimationFrames(
          affinityCode: 'warm_sun',
          stageNo: 1,
        ).first,
        'assets/Mobile/TinhLinhNangAm/Stage1/pvp/race/race_F01.png',
      );
      expect(
        PvpAssetResolver.petAnimationFrames(
          affinityCode: 'dawn',
          stageNo: 2,
        ).last,
        'assets/Mobile/Tinh Linh Bình Minh/stage2/pvp/race/race_F12.png',
      );
    });
  });

  testWidgets('renders both pet sprites on the actual lane baselines', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PvPRacingEnvironment(
            isMoving: false,
            trackProgress: 0,
            myProgress: 0,
            opponentProgress: 0,
            opponentName: 'Đối thủ',
            racePhase: 'ready',
            isFinished: false,
            onClose: () {},
            mapAssets: PvpAssetResolver.mapsForNow(
              DateTime(2026, 1, 1, 12),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pets = find.byType(PvpPetAnimation);
    expect(pets, findsNWidgets(2));
    expect(tester.getBottomLeft(pets.at(0)).dy, closeTo(800 * 0.58, 0.1));
    expect(tester.getBottomLeft(pets.at(1)).dy, closeTo(800 * 0.73, 0.1));
    expect(tester.takeException(), isNull);
  });
}
