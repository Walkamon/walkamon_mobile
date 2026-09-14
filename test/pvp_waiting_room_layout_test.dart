import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/providers/pvp_provider.dart';
import 'package:walkamon_mobile/screen/gameplay/pvp/pvp_waiting_room_screen.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

class _TestPvpProvider extends PvpProvider {
  _TestPvpProvider(this.state);

  final PvpMatchmakingState state;

  @override
  PvpMatchmakingState get matchmakingState => state;

  @override
  String get petName => 'Passed';

  @override
  int get todaySteps => 0;

  @override
  int get currentEnergy => 59;

  @override
  int get maxEnergy => 100;

  @override
  int get currentBond => 97;

  @override
  DateTime estimatedServerNow() => DateTime(2026, 1, 1, 22);
}

Future<void> _pumpWaitingRoom(
  WidgetTester tester,
  PvpProvider provider, {
  String affinityCode = 'sprout',
  int stageNo = 0,
  String animationType = 'idle',
  Locale locale = const Locale('vi'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PvPWaitingRoomScreen(
          pvpProvider: provider,
          activePetAffinityCode: affinityCode,
          activePetStageNo: stageNo,
          activePetAnimationType: animationType,
          onStartMatchmaking: () {},
          onCancelMatchmaking: () {},
          onInviteFriend: (_, _) {},
          onShowIncomingChallenges: () {},
          onShowMatchHistory: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectMatchmakingLayout(
  WidgetTester tester, {
  required String bondLabel,
  required String searchStatus,
  required String cancelButton,
  required String friendButton,
}) {
  final statsScroller = find.byType(SingleChildScrollView);
  final bond = find.text(bondLabel);
  final status = find.text(searchStatus);
  final cancel = find.text(cancelButton);
  final friend = find.text(friendButton);

  expect(statsScroller, findsOneWidget);
  expect(bond, findsOneWidget);
  // The modal title is stacked stroke/fill text.
  expect(status, findsWidgets);
  expect(cancel, findsWidgets);
  expect(friend, findsWidgets);

  final scrollerRect = tester.getRect(statsScroller);
  final screenRect = tester.getRect(find.byType(Scaffold));
  final bondRect = tester.getRect(bond);
  final statusRect = tester.getRect(status.last);
  final cancelRect = tester.getRect(cancel.last);
  final friendRect = tester.getRect(friend.last);

  expect(bondRect.bottom, lessThanOrEqualTo(scrollerRect.bottom));
  expect(statusRect.top, greaterThanOrEqualTo(screenRect.top));
  expect(statusRect.bottom, lessThan(cancelRect.top));
  expect(cancelRect.bottom, lessThanOrEqualTo(screenRect.bottom));
  expect(friendRect.bottom, lessThanOrEqualTo(screenRect.bottom));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('renders the waiting room in English', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 698));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = _TestPvpProvider(PvpMatchmakingState.waiting);
    addTearDown(provider.dispose);

    await _pumpWaitingRoom(tester, provider, locale: const Locale('en'));

    _expectMatchmakingLayout(
      tester,
      bondLabel: 'Bond:',
      searchStatus: 'Searching for an opponent...',
      cancelButton: 'Cancel search',
      friendButton: 'Challenge a friend',
    );
  });

  testWidgets('uses the active Home pet visual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 698));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = _TestPvpProvider(PvpMatchmakingState.idle);
    addTearDown(provider.dispose);

    await _pumpWaitingRoom(
      tester,
      provider,
      affinityCode: 'dawn',
      stageNo: 2,
      animationType: 'idle_front',
    );

    final preview = tester.widget<PetRuntimePreview>(
      find.byType(PetRuntimePreview),
    );
    expect(preview.affinityCode, 'dawn');
    expect(preview.stageNo, 2);
    expect(preview.animationType, 'idle_front');
    expect(tester.takeException(), isNull);
  });

  testWidgets('matchmaking status does not clip the Bond row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 698));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final provider = _TestPvpProvider(PvpMatchmakingState.waiting);
    addTearDown(provider.dispose);

    await _pumpWaitingRoom(tester, provider);

    _expectMatchmakingLayout(
      tester,
      bondLabel: 'Độ gắn kết:',
      searchStatus: 'Đang tìm đối thủ...',
      cancelButton: 'Hủy tìm trận',
      friendButton: 'Thách đấu với bạn bè',
    );
  });

  testWidgets('matchmaking modal does not reflow the action buttons', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 698));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final idleProvider = _TestPvpProvider(PvpMatchmakingState.idle);
    final waitingProvider = _TestPvpProvider(PvpMatchmakingState.waiting);
    addTearDown(idleProvider.dispose);
    addTearDown(waitingProvider.dispose);

    await _pumpWaitingRoom(tester, idleProvider);
    final idleButtonTop = tester.getRect(find.text('Thách đấu với bạn bè')).top;

    await _pumpWaitingRoom(tester, waitingProvider);
    final waitingButtonTop = tester
        .getRect(find.text('Thách đấu với bạn bè'))
        .top;

    expect(waitingButtonTop, closeTo(idleButtonTop, 0.1));
    expect(tester.takeException(), isNull);
  });
}
