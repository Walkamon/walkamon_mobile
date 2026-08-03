import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
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

    test('maps each theme lane center through centered BoxFit.cover', () {
      expect(
        pvpLaneCenterY(
          viewportWidth: 625,
          viewportHeight: 873,
          mapAsset: AppAssets.pvpMapNightStart,
          laneIndex: 0,
        ),
        closeTo(318.44, 0.1),
      );
      expect(
        pvpLaneCenterY(
          viewportWidth: 625,
          viewportHeight: 873,
          mapAsset: AppAssets.pvpMapNightStart,
          laneIndex: 1,
        ),
        closeTo(603.17, 0.1),
      );
      expect(
        pvpLaneCenterY(
          viewportWidth: 625,
          viewportHeight: 873,
          mapAsset: AppAssets.pvpMapMorningStart,
          laneIndex: 0,
        ),
        closeTo(436.5, 0.1),
      );
      expect(
        pvpLaneCenterY(
          viewportWidth: 625,
          viewportHeight: 873,
          mapAsset: AppAssets.pvpMapMorningStart,
          laneIndex: 1,
        ),
        closeTo(610.11, 0.1),
      );
    });

    test('pets start behind the line and finish inside the track', () {
      const width = 625.0;
      const height = 873.0;
      const runnerWidth = 108.0;
      const petWidth = runnerWidth - 24;
      final startLineX = 92 * (width / 1440);

      final start = pvpRunnerScreenX(
        viewportWidth: width,
        viewportHeight: height,
        progress: -10,
        runnerWidth: runnerWidth,
      );
      final finish = pvpRunnerScreenX(
        viewportWidth: width,
        viewportHeight: height,
        progress: 120,
        runnerWidth: runnerWidth,
      );

      expect(start + petWidth * 0.40, closeTo(startLineX, 0.1));
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

  testWidgets('renders both pet sprite centers on the lane centers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
            mapAssets: PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12)),
          ),
        ),
      ),
    );
    await tester.pump();

    final pets = find.byType(PvpPetAnimation);
    expect(pets, findsNWidgets(2));
    expect(tester.getCenter(pets.at(0)).dy, closeTo(400, 0.1));
    expect(tester.getCenter(pets.at(1)).dy, closeTo(525, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('race timeline fills and switches maps through the finish', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final maps = PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12));

    Widget buildEnvironment(double trackProgress) {
      return MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PvPRacingEnvironment(
            isMoving: false,
            trackProgress: trackProgress,
            myProgress: trackProgress * 100,
            opponentProgress: trackProgress * 100,
            opponentName: 'Đối thủ',
            racePhase: 'running',
            isFinished: false,
            onClose: () {},
            mapAssets: maps,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildEnvironment(0));
    await tester.pump();
    expect(find.byKey(ValueKey(maps[0])), findsOneWidget);

    await tester.pumpWidget(buildEnvironment(0.5));
    await tester.pump(const Duration(milliseconds: 160));

    final track = find.byKey(const ValueKey('pvp-race-progress-track'));
    final fill = find.byKey(const ValueKey('pvp-race-progress-fill'));
    expect(track, findsOneWidget);
    expect(fill, findsOneWidget);
    expect(tester.getSize(fill).height, closeTo(12, 0.1));
    expect(
      tester.getSize(fill).width,
      closeTo(tester.getSize(track).width * 0.5, 0.1),
    );
    expect(find.byKey(ValueKey(maps[0])), findsNothing);
    expect(find.byKey(ValueKey(maps[1])), findsOneWidget);

    await tester.pumpWidget(buildEnvironment(0.9));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byKey(ValueKey(maps[1])), findsNothing);
    expect(find.byKey(ValueKey(maps[2])), findsOneWidget);
    expect(
      tester.getSize(fill).width,
      closeTo(tester.getSize(track).width * 0.9, 0.1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes the race HUD in English', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PvPRacingEnvironment(
            isMoving: false,
            trackProgress: 0.5,
            myProgress: 50,
            opponentProgress: 50,
            opponentName: 'Rival',
            racePhase: 'go',
            isFinished: false,
            onClose: () {},
            mapAssets: PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You'), findsOneWidget);
    expect(find.text('GO!'), findsOneWidget);
    expect(find.byTooltip('Leave race'), findsOneWidget);
    expect(find.bySemanticsLabel('Race progress: 50%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
