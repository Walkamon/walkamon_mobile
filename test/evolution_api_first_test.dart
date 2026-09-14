import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/pet_evolution_models.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/evolution/spirit_evolution_screen.dart';
import 'package:walkamon_mobile/widgets/motion/evolution_sequence.dart';

PetOverviewResponse overview({bool canEvolve = true, int stage = 0}) =>
    PetOverviewResponse(
      petId: 'pet',
      nickname: 'Lumina',
      formName: 'Lumina',
      affinityCode: stage == 0 ? 'sprout' : 'warm_sun',
      level: 15,
      currentExp: 20,
      maxExp: 100,
      currentEnergy: 80,
      maxEnergy: 100,
      currentLifeForce: 80,
      maxLifeForce: 100,
      currentBond: 100,
      maxBond: 100,
      stageNo: stage,
      stageName: 'Stage $stage',
      animationType: 'idle',
      canEvolve: canEvolve,
      nextEvolutionLevel: 15,
    );

void main() {
  testWidgets(
    'reveal uses the confirmed form and background closes only presentation',
    (tester) async {
      final response = Completer<bool>();
      var stage = 0;
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => SpiritEvolutionScreen(
                level: 15,
                bonding: 100,
                initialIsEvolved: stage != 0,
                overview: overview(stage: stage, canEvolve: stage == 0),
                onEvolve: ([id]) {
                  calls++;
                  return response.future;
                },
                onRefresh: () async => update(() => stage = 1),
              ),
            ),
          ),
        ),
      );
      final button = find
          .byWidgetPredicate((w) => w is InkWell && w.onTap != null)
          .last;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.byType(EvolutionSequence), findsNothing);
      response.complete(true);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final sequence = tester.widget<EvolutionSequence>(
        find.byType(EvolutionSequence),
      );
      expect(sequence.before.stageNo, 0);
      expect(sequence.after.stageNo, 1);
      expect(calls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(EvolutionSequence), findsNothing);
      expect(stage, 1);
      expect(calls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  Widget app({
    required Future<bool> Function([String?]) submit,
    bool allowed = true,
    Future<void> Function()? refresh,
  }) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SpiritEvolutionScreen(
        level: 15,
        bonding: 100,
        initialIsEvolved: false,
        overview: overview(canEvolve: allowed),
        onEvolve: submit,
        onRefresh: refresh,
      ),
    ),
  );

  testWidgets(
    'pending request has no celebration; double tap does not resubmit',
    (tester) async {
      final response = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        app(
          submit: ([id]) {
            calls++;
            return response.future;
          },
        ),
      );
      final button = find
          .byWidgetPredicate((w) => w is InkWell && w.onTap != null)
          .last;
      await tester.ensureVisible(button);
      final position = tester.getCenter(button);
      await tester.tap(button);
      await tester.pump();
      await tester.tapAt(position);
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(EvolutionSequence), findsNothing);
      response.complete(false);
      await tester.pump();
      expect(find.byType(EvolutionSequence), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('server canEvolve false is not overridden by level', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        allowed: false,
        submit: ([id]) async {
          calls++;
          return true;
        },
      ),
    );
    final enabled = find.byWidgetPredicate(
      (w) => w is InkWell && w.onTap != null,
    );
    expect(enabled, findsNothing);
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refresh failure after commit does not send evolution again', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        submit: ([id]) async {
          calls++;
          return true;
        },
        refresh: () async => throw StateError('offline'),
      ),
    );
    final button = find
        .byWidgetPredicate((w) => w is InkWell && w.onTap != null)
        .last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(EvolutionSequence), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
