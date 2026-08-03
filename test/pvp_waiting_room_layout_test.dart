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
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
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

void main() {
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

    final statsScroller = find.byType(SingleChildScrollView);
    final bondLabel = find.text('Độ gắn kết:');
    final searchStatus = find.text('Đang tìm đối thủ...');
    final cancelButton = find.text('Hủy tìm trận');
    final friendButton = find.text('Thách đấu với bạn bè');

    expect(statsScroller, findsOneWidget);
    expect(bondLabel, findsOneWidget);
    expect(searchStatus, findsOneWidget);
    expect(cancelButton, findsOneWidget);
    expect(friendButton, findsOneWidget);

    final scrollerRect = tester.getRect(statsScroller);
    final bondRect = tester.getRect(bondLabel);
    final statusRect = tester.getRect(searchStatus);
    final cancelRect = tester.getRect(cancelButton);
    final friendRect = tester.getRect(friendButton);

    expect(bondRect.bottom, lessThanOrEqualTo(scrollerRect.bottom));
    expect(bondRect.bottom, lessThan(statusRect.top));
    expect(statusRect.bottom, lessThan(cancelRect.top));
    expect(cancelRect.bottom, lessThan(friendRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('matchmaking status pushes the action buttons down', (
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

    expect(waitingButtonTop, greaterThan(idleButtonTop));
    expect(waitingButtonTop - idleButtonTop, closeTo(30, 0.1));
    expect(tester.takeException(), isNull);
  });
}
