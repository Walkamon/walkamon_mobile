import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('renders localized PvP result and wallet reward', (tester) async {
    final result = PvpMatchResultResponse(
      match: PvpMatchResponse(
        matchId: 'match-1',
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
    expect(find.text('REWARDS RECEIVED'), findsOneWidget);
    expect(find.text('+2 Dewdrops'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
