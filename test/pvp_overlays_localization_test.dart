import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/data/models/pvp_models.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/widgets/pvp_overlays.dart';

Widget _localizedHarness(Locale locale, Widget child) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'renders the localized opponent inside the rich waiting message',
    (tester) async {
      await tester.pumpWidget(
        _localizedHarness(
          const Locale('en'),
          PvPWaitingFriendOverlay(opponentName: 'Mina', onCancel: () {}),
        ),
      );
      await tester.pump();

      expect(find.text('Invitation sent!'), findsOneWidget);
      expect(
        find.text('Waiting for Mina to respond...', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Cancel request'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders localized ranked result and wallet reward', (
    tester,
  ) async {
    final result = PvpMatchResultResponse(
      match: PvpMatchResponse(
        matchId: 'match-1',
        matchTypeCode: 'ranked',
        statusCode: 'finished',
        participants: [
          PvpParticipantResponse(
            participantTypeCode: 'user',
            userId: 'me',
            displayName: 'Me',
            score: 120,
            resultCode: 'win',
          ),
          PvpParticipantResponse(
            participantTypeCode: 'bot',
            botProfileId: 'bot-1',
            displayName: 'Mina',
            score: 90,
            resultCode: 'lose',
          ),
        ],
      ),
      mmrBefore: 1000,
      mmrDelta: 0,
      mmrAfter: 1000,
      tierChanged: false,
      canClaimReward: false,
      claimedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      _localizedHarness(
        const Locale('en'),
        PvPFinishedOverlay(
          result: result,
          isLoading: false,
          currentUserId: 'me',
          opponentName: 'Mina',
          onContinue: () {},
          claimResponse: PvpRewardClaimResponse(
            walletBalance: 1002,
            walletReward: 2,
            rewardItems: const [],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Victory!'), findsOneWidget);
    expect(find.text('You defeated Mina'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.iconWin,
      ),
      findsOneWidget,
    );
    expect(find.text('REWARDS RECEIVED'), findsOneWidget);
    expect(find.text('+2 Dewdrops'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('pvp-finished-card'))).height,
      lessThan(560),
    );
    // Outlined game text uses separate stroke and fill painters.
    expect(find.text('Continue'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('friendly result never exposes claim or reward UI', (
    tester,
  ) async {
    PvpMatchResultResponse friendlyResult({required DateTime? claimedAt}) {
      return PvpMatchResultResponse(
        match: PvpMatchResponse(
          matchId: 'friendly-match-1',
          matchTypeCode: 'friendly',
          statusCode: 'finished',
          participants: [
            PvpParticipantResponse(
              participantTypeCode: 'user',
              userId: 'me',
              displayName: 'Me',
              resultCode: 'win',
            ),
          ],
        ),
        mmrBefore: 1000,
        mmrDelta: 25,
        mmrAfter: 1025,
        tierChanged: false,
        canClaimReward: true,
        claimedAt: claimedAt,
      );
    }

    Widget overlay(PvpMatchResultResponse result) {
      return _localizedHarness(
        const Locale('en'),
        PvPFinishedOverlay(
          result: result,
          isLoading: false,
          currentUserId: 'me',
          opponentName: 'Mina',
          onContinue: () {},
          onClaimReward: () async {},
          claimResponse: PvpRewardClaimResponse(
            walletBalance: 1002,
            walletReward: 2,
            rewardItems: const [],
          ),
        ),
      );
    }

    await tester.pumpWidget(overlay(friendlyResult(claimedAt: null)));
    await tester.pump();
    expect(find.text('Claim reward'), findsNothing);

    await tester.pumpWidget(
      overlay(friendlyResult(claimedAt: DateTime(2026, 1, 1))),
    );
    await tester.pump();
    expect(find.text('Reward claimed'), findsNothing);
    expect(find.text('REWARDS RECEIVED'), findsNothing);
    expect(find.text('+2 Dewdrops'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not expose MMR on the ranked result overlay', (
    tester,
  ) async {
    final result = PvpMatchResultResponse(
      match: PvpMatchResponse(
        matchId: 'ranked-match-1',
        matchTypeCode: 'ranked',
        statusCode: 'finished',
        participants: [
          PvpParticipantResponse(
            participantTypeCode: 'user',
            userId: 'me',
            displayName: 'Me',
            resultCode: 'win',
          ),
        ],
      ),
      mmrBefore: 1000,
      mmrDelta: 25,
      mmrAfter: 1025,
      tierChanged: false,
      canClaimReward: false,
      claimedAt: null,
    );

    await tester.pumpWidget(
      _localizedHarness(
        const Locale('en'),
        PvPFinishedOverlay(
          result: result,
          isLoading: false,
          currentUserId: 'me',
          opponentName: 'Mina',
          onContinue: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Victory!'), findsOneWidget);
    expect(find.text('MMR'), findsNothing);
    expect(find.text('Current MMR'), findsNothing);
    expect(find.text('+25'), findsNothing);
    expect(find.text('1,025'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
