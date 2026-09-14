import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/datasources/remote/pvp_sprint_datasource.dart';
import 'package:walkamon_mobile/data/models/pvp_models.dart';
import 'package:walkamon_mobile/providers/pvp_provider.dart';

class _Signal extends Fake implements PvpSignalRService {
  @override
  bool get isConnected => true;
  @override
  bool get isMatchRoomJoined => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<bool> joinMatch(String id) async => true;
  @override
  void setEventHandlers({
    required void Function(Map<String, dynamic>) onAssigned,
    required void Function(Map<String, dynamic>) onProgress,
    required void Function(Map<String, dynamic>) onFinished,
    required void Function(Map<String, dynamic>) onSettling,
    required void Function(Map<String, dynamic>) onCancelled,
    required void Function(Map<String, dynamic>) onCountdownStarted,
    required void Function(Map<String, dynamic>) onStarted,
    void Function(Map<String, dynamic>)? onForfeited,
    void Function(Map<String, dynamic>)? onPresenceChanged,
    void Function(Map<String, dynamic>)? onQueueFailed,
  }) {}
  @override
  void setReconnectedHandler(Future<void> Function()? callback) {}
}

PvpMatchResponse _match({String status = 'running', String? reason}) =>
    PvpMatchResponse(
      matchId: 'race',
      matchTypeCode: 'ranked',
      statusCode: status,
      finishReasonCode: reason,
      forfeitedByUserId: reason == 'user_forfeit' ? 'me' : null,
      serverTime: DateTime.now().toUtc(),
      startedAt: DateTime.now().toUtc(),
      endedAt: DateTime.now().toUtc().add(const Duration(seconds: 30)),
      participants: [
        PvpParticipantResponse(
          participantTypeCode: 'user',
          userId: 'me',
          distanceUnits: 110000,
          expectedDistanceUnits: 300000,
          resultCode: status == 'finished' ? 'lose' : null,
        ),
        PvpParticipantResponse(
          participantTypeCode: 'bot',
          distanceUnits: 100000,
          expectedDistanceUnits: 300000,
          resultCode: status == 'finished' ? 'win' : null,
        ),
      ],
    );

ApiResponse<PvpMatchResponse> _ok(PvpMatchResponse match) =>
    ApiResponse(success: true, status: 200, message: 'ok', data: match);

class _Data extends PvpSprintDatasource {
  PvpMatchResponse snapshot = _match();
  int calls = 0;
  final pending = Completer<ApiResponse<PvpMatchResponse>>();
  bool holdNextGet = false;
  Completer<ApiResponse<PvpMatchResponse>>? pendingGet;
  bool resultUnavailable = false;
  @override
  Future<ApiResponse<PvpMatchResponse>> getMatch(String id) async {
    if (holdNextGet) {
      holdNextGet = false;
      final pending = Completer<ApiResponse<PvpMatchResponse>>();
      pendingGet = pending;
      return pending.future;
    }
    return _ok(snapshot);
  }

  @override
  Future<ApiResponse<PvpMatchResponse>> forfeitMatch(String id) {
    calls++;
    return pending.future;
  }

  @override
  Future<ApiResponse<PvpMatchResultResponse>> getMatchResult(String id) async =>
      resultUnavailable
      ? ApiResponse(success: false, status: 503, message: 'retry')
      : ApiResponse(
          success: true,
          status: 200,
          message: 'ok',
          data: PvpMatchResultResponse(
            match: snapshot,
            mmrBefore: 1000,
            mmrDelta: -16,
            mmrAfter: 984,
            tierChanged: false,
            canClaimReward: false,
          ),
        );
}

class _Provider extends PvpProvider {
  _Provider(_Data data) : super(pvpDatasource: data, signalRService: _Signal());
  @override
  Future<void> refreshPetStatus() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<_Provider> setup(_Data data) async {
    final provider = _Provider(data)..setCurrentUserId('me');
    addTearDown(provider.dispose);
    await provider.handleSignalREvent({
      'eventType': 'match.assigned',
      'payload': {'matchId': 'race'},
    });
    return provider;
  }

  test('parse preserves server forfeit metadata', () {
    final match = PvpMatchResponse.fromJson({
      'matchId': 'race',
      'statusCode': 'finished',
      'finishReasonCode': 'user_forfeit',
      'forfeitedByUserId': 'me',
    });
    expect(match.finishReasonCode, 'user_forfeit');
    expect(match.forfeitedByUserId, 'me');
  });

  test(
    'idle and ordinary races are not forfeits when metadata is null',
    () async {
      final data = _Data();
      final empty = _Provider(data);
      expect(empty.isForfeitMatch, isFalse);
      empty.dispose();
      final provider = await setup(data);
      expect(provider.isForfeitMatch, isFalse);
    },
  );

  test('disposed provider ignores pending forfeit without notifying', () async {
    final data = _Data();
    final provider = _Provider(data)..setCurrentUserId('me');
    await provider.handleSignalREvent({
      'eventType': 'match.assigned',
      'payload': {'matchId': 'race'},
    });
    final request = provider.forfeitMatch();
    provider.dispose();
    data.pending.complete(
      _ok(_match(status: 'finished', reason: 'user_forfeit')),
    );
    expect(await request, isFalse);
    expect(provider.matchResult, isNull);
  });

  test(
    'same user rejoining same match ignores the previous session response',
    () async {
      final data = _Data();
      final provider = await setup(data);
      final request = provider.forfeitMatch();
      provider.clearMatchState();
      await provider.handleSignalREvent({
        'eventType': 'match.assigned',
        'payload': {'matchId': 'race'},
      });
      data.pending.complete(
        _ok(_match(status: 'finished', reason: 'user_forfeit')),
      );
      expect(await request, isFalse);
      expect(provider.matchResult, isNull);
      expect(provider.isRaceFinished, isFalse);
    },
  );

  test(
    'pending and double tap never invent a result or stop the race',
    () async {
      final data = _Data();
      final provider = await setup(data);
      final first = provider.forfeitMatch();
      final second = provider.forfeitMatch();
      expect(identical(first, second), isTrue);
      expect(data.calls, 1);
      expect(provider.forcedResultCode, isNull);
      expect(provider.matchResult, isNull);
      expect(provider.isRaceFinished, isFalse);
      data.snapshot = _match(status: 'finished', reason: 'user_forfeit');
      data.pending.complete(_ok(data.snapshot));
      expect(await first, isTrue);
      expect(provider.finishPresentationCompleted, isTrue);
      expect(provider.myProgress, lessThan(100));
      expect(provider.matchResult?.mmrDelta, -16);
    },
  );

  for (final status in [409, 503]) {
    test(
      '$status while server remains running does not forge defeat',
      () async {
        final data = _Data();
        final provider = await setup(data);
        final request = provider.forfeitMatch();
        data.pending.complete(
          ApiResponse(success: false, status: status, message: 'not confirmed'),
        );
        expect(await request, isFalse);
        expect(provider.matchmakingState, PvpMatchmakingState.running);
        expect(provider.matchResult, isNull);
        expect(provider.forcedResultCode, isNull);
        expect(provider.forfeitFailure, isNotNull);
      },
    );
  }

  test(
    'timeout after commit reconciles confirmed result without replay crossing',
    () async {
      final data = _Data();
      final provider = await setup(data);
      final request = provider.forfeitMatch();
      data.snapshot = _match(status: 'finished', reason: 'user_forfeit');
      data.pending.completeError(TimeoutException('ambiguous'));
      expect(await request, isTrue);
      expect(provider.finishPresentationCompleted, isTrue);
      expect(provider.matchResult?.mmrAfter, 984);
    },
  );

  test('missing result never manufactures MMR or reward', () async {
    final data = _Data()..resultUnavailable = true;
    final provider = await setup(data);
    final request = provider.forfeitMatch();
    data.snapshot = _match(status: 'finished', reason: 'user_forfeit');
    data.pending.complete(_ok(data.snapshot));
    expect(await request, isTrue);
    expect(provider.finishPresentationCompleted, isTrue);
    expect(provider.matchResult, isNull);
  });

  test('account switch ignores an old pending forfeit response', () async {
    final data = _Data();
    final provider = await setup(data);
    final request = provider.forfeitMatch();
    provider.clearMatchState();
    provider.setCurrentUserId('other');
    data.pending.complete(
      _ok(_match(status: 'finished', reason: 'user_forfeit')),
    );
    expect(await request, isFalse);
    expect(provider.matchResult, isNull);
    expect(provider.matchmakingState, PvpMatchmakingState.idle);
  });

  test(
    'account switch during match reconciliation ignores stale GET',
    () async {
      final data = _Data();
      final provider = await setup(data);
      data.holdNextGet = true;
      final request = provider.forfeitMatch();
      data.pending.completeError(TimeoutException('ambiguous'));
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(data.pendingGet, isNotNull);
      provider.setCurrentUserId('other');
      data.pendingGet!.complete(
        _ok(_match(status: 'finished', reason: 'user_forfeit')),
      );
      expect(await request, isFalse);
      expect(provider.matchResult, isNull);
      expect(provider.matchmakingState, PvpMatchmakingState.running);
    },
  );
}
