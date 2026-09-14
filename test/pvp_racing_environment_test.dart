import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/pvp_asset_resolver.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/pvp_race_contract.dart';
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

    test('finish map enters from the right before the checker is reached', () {
      final beforeApproach = PvpRoutePresentationContract.resolve(.70);
      final approaching = PvpRoutePresentationContract.resolve(.78);
      final finish = PvpRoutePresentationContract.resolve(25 / 30);

      expect(beforeApproach.nextMapOpacity, 0);
      expect(approaching.phaseIndex, 1);
      expect(approaching.nextPhaseIndex, 2);
      expect(approaching.nextMapOpacity, greaterThan(0));
      expect(approaching.incomingMapOffsetFraction, greaterThan(0));
      expect(finish.phaseIndex, 2);
      expect(finish.incomingMapOffsetFraction, 0);
    });

    test('start stripe travels left and fades instead of snapping away', () {
      final opening = PvpRoutePresentationContract.resolve(0);
      final departing = PvpRoutePresentationContract.resolve(.12);
      final trail = PvpRoutePresentationContract.resolve(5 / 30);

      expect(opening.startLineOpacity, 1);
      expect(opening.startLineOffsetFraction, 0);
      expect(departing.startLineOpacity, inExclusiveRange(0, 1));
      expect(departing.startLineOffsetFraction, lessThan(0));
      expect(trail.startLineOpacity, 0);
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
      final startLineX = 510 * (width / 1440);

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

      expect(start - runnerWidth / 2, greaterThanOrEqualTo(8));
      expect(start + runnerWidth / 2, lessThanOrEqualTo(startLineX - 8));
      expect(finish + runnerWidth / 2, lessThanOrEqualTo(width - 8));
    });

    test('portrait camera exposes both baked route markings', () {
      expect(pvpMapHorizontalAlignmentX(AppAssets.pvpMapMorningStart), -1);
      expect(pvpMapHorizontalAlignmentX(AppAssets.pvpMapMorningLoop), 0);
      expect(pvpMapHorizontalAlignmentX(AppAssets.pvpMapMorningFinish), 1);

      final finishLineX = PvpTrackCoordinateContract.finishLineScreenX(
        viewportWidth: 400,
        viewportHeight: 800,
        mapAlignmentX: 1,
      );
      expect(finishLineX, inInclusiveRange(220, 250));

      final start = pvpRunnerScreenX(
        viewportWidth: 400,
        viewportHeight: 800,
        progress: 0,
        runnerWidth: 108,
        mapAsset: AppAssets.pvpMapMorningStart,
      );
      expect(start - 108 / 2, greaterThanOrEqualTo(8));
    });

    test('all seven pet silhouettes fully cross and remain visible', () {
      const forms = [
        ('sprout', 1),
        ('warm_sun', 1),
        ('warm_sun', 2),
        ('moonlight', 1),
        ('moonlight', 2),
        ('dawn', 1),
        ('dawn', 2),
      ];
      const width = 400.0;
      const height = 800.0;
      final finishLineX = PvpTrackCoordinateContract.finishLineScreenX(
        viewportWidth: width,
        viewportHeight: height,
        mapAlignmentX: 1,
      );

      for (final form in forms) {
        final metrics = PvpPetVisualMetrics.resolve(form.$1, form.$2);
        final petSize = metrics.correctedSize(138);
        final trailingOffset = metrics.trailingEdgeOffsetX(petSize);
        final leadingOffset = metrics.leadingEdgeOffsetX(petSize);
        final finish = pvpRunnerScreenX(
          viewportWidth: width,
          viewportHeight: height,
          progress: 100,
          runnerWidth: petSize + 24,
          bodyCenterOffsetX: metrics.bodyCenterOffsetX(petSize),
          crossingAnchorOffsetX: trailingOffset,
          leadingAnchorOffsetX: leadingOffset,
          mapAsset: AppAssets.pvpMapMorningFinish,
        );

        expect(
          finish + trailingOffset,
          greaterThan(finishLineX),
          reason: '${form.$1} stage ${form.$2} must fully clear the stripe',
        );
        expect(
          finish + leadingOffset,
          lessThanOrEqualTo(width - 8),
          reason: '${form.$1} stage ${form.$2} must remain fully visible',
        );
      }
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
    // Per-form alpha-footprint correction may move the transparent 512x512
    // image box by a sub-pixel while the visible paws stay on the lane.
    expect(tester.getCenter(pets.at(0)).dy, closeTo(400, 2));
    expect(tester.getCenter(pets.at(1)).dy, closeTo(525, 2));
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
    expect(
      find.byKey(const ValueKey('pvp-outgoing-start-line')),
      findsOneWidget,
    );

    await tester.pumpWidget(buildEnvironment(0.5));
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.byKey(const ValueKey('pvp-race-status')), findsOneWidget);
    expect(find.text('Còn 15s'), findsOneWidget);
    expect(find.text('Đường rừng'), findsOneWidget);
    expect(find.byKey(ValueKey(maps[0])), findsNothing);
    expect(find.byKey(ValueKey(maps[1])), findsOneWidget);

    await tester.pumpWidget(buildEnvironment(0.9));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.byKey(ValueKey(maps[1])), findsOneWidget);
    expect(find.byKey(ValueKey(maps[2])), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pvp-incoming-finish-line')),
      findsOneWidget,
    );
    expect(find.text('Còn 3s'), findsOneWidget);
    expect(find.text('Về đích'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('pvp-race-status')), findsOneWidget);
    expect(find.text('15s left'), findsOneWidget);
    expect(find.text('Forest trail'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('deduplicates active and transient copies of one item VFX', (
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
            isMoving: true,
            trackProgress: .5,
            myProgress: 50,
            opponentProgress: 48,
            opponentName: 'Đối thủ',
            racePhase: 'running',
            isFinished: false,
            onClose: () {},
            mapAssets: PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12)),
            myActiveEffects: const ['pvp_speed_up'],
            myTransientEffect: 'haste',
            transientVfxSequence: 2,
            animationsPaused: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PvpFrameAnimation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finish presentation uses dedicated win and lose sequences', (
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
            trackProgress: 1,
            myProgress: 100,
            opponentProgress: 100,
            opponentName: 'Đối thủ',
            racePhase: 'finished',
            isFinished: false,
            showFinishReaction: true,
            finishResultCode: 'win',
            onClose: () {},
            mapAssets: PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12)),
            myAnimationState: 'win',
            opponentAnimationState: 'lose',
          ),
        ),
      ),
    );
    await tester.pump();

    final pets = tester.widgetList<PvpPetAnimation>(
      find.byType(PvpPetAnimation),
    );
    expect(pets.map((pet) => pet.state), ['lose', 'win']);
    expect(pets.every((pet) => pet.playing), isTrue);
    expect(find.byKey(const ValueKey('pvp-finish-reaction')), findsOneWidget);
    expect(find.text('Chiến thắng!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reports crossing only after the full winner silhouette clears line',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var crossings = 0;

      Widget buildAt(double myProgress) => MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PvPRacingEnvironment(
            isMoving: true,
            trackProgress: 1,
            myProgress: myProgress,
            opponentProgress: 72,
            opponentName: 'Đối thủ',
            racePhase: 'finished',
            isFinished: false,
            finishResultCode: 'win',
            onWinnerCrossed: () => crossings++,
            onClose: () {},
            mapAssets: PvpAssetResolver.mapsForNow(DateTime(2026, 1, 1, 12)),
            animationsPaused: true,
          ),
        ),
      );

      await tester.pumpWidget(buildAt(95));
      await tester.pump();
      expect(crossings, 0);

      await tester.pumpWidget(buildAt(99));
      await tester.pump();
      expect(
        crossings,
        0,
        reason: 'body centre alone is not a complete silhouette crossing',
      );

      await tester.pumpWidget(buildAt(100));
      await tester.pump();
      expect(crossings, 1);
      await tester.pump();
      expect(crossings, 1, reason: 'crossing callback must be exactly-once');
    },
  );

  testWidgets('lose reaction settles on the defeated pose instead of neutral', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PvpPetAnimation(
          affinityCode: 'sprout',
          stageNo: 1,
          state: 'lose',
          playing: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      endsWith('/pvp/lose/lose_F04.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('race-to-win transition restarts and holds the happy pose', (
    tester,
  ) async {
    Widget buildPet(String state) => MaterialApp(
      home: PvpPetAnimation(
        affinityCode: 'sprout',
        stageNo: 1,
        state: state,
        playing: true,
      ),
    );

    await tester.pumpWidget(buildPet('race'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(buildPet('win'));
    await tester.pump();
    var image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, endsWith('/win/win_F01.png'));
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .83);

    await tester.pump(const Duration(milliseconds: 1100));
    image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, endsWith('/win/win_F08.png'));
    expect(tester.takeException(), isNull);
  });
}
