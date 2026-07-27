import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/datasources/remote/pvp_sprint_datasource.dart';
import 'package:walkamon_mobile/data/models/pvp_models.dart';
import 'package:walkamon_mobile/providers/pvp_provider.dart';

class _FakePvpSprintDatasource extends PvpSprintDatasource {
  final List<String> fetchedMatchIds = [];

  @override
  Future<ApiResponse<PvpMatchResponse>> getMatch(String matchId) async {
    fetchedMatchIds.add(matchId);
    return ApiResponse<PvpMatchResponse>(
      success: true,
      status: 200,
      message: 'ok',
      data: PvpMatchResponse(
        matchId: matchId,
        matchTypeCode: 'ranked',
        statusCode: 'countdown',
        participants: [],
      ),
    );
  }
}

class _FakeSignalRService implements PvpSignalRService {
  final List<String> joinedMatchIds = [];

  @override
  bool get isConnected => true;

  @override
  bool get isMatchRoomJoined => joinedMatchIds.isNotEmpty;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> joinMatch(String matchId) async {
    joinedMatchIds.add(matchId);
    return true;
  }

  @override
  Future<void> leaveMatch(String matchId) async {}

  @override
  void setEventHandlers({
    required void Function(Map<String, dynamic> event) onAssigned,
    required void Function(Map<String, dynamic> event) onProgress,
    required void Function(Map<String, dynamic> event) onFinished,
    required void Function(Map<String, dynamic> event) onSettling,
    required void Function(Map<String, dynamic> event) onCancelled,
  }) {}

  @override
  Future<void> emitEvent(Map<String, dynamic> event) async {
    // No-op for fake service; tests call provider.handleSignalREvent directly.
  }

  @override
  void setReconnectedHandler(Future<void> Function()? onReconnected) {
    // No-op for fake service
  }

  @override
  String? get hubUrl => null;

  @override
  String? get connectionId => 'fake-conn';
}

void main() {
  test(
    'assigned event refreshes match snapshot and moves to countdown',
    () async {
      final datasource = _FakePvpSprintDatasource();
      final signalRService = _FakeSignalRService();
      final provider = PvpProvider(
        pvpDatasource: datasource,
        signalRService: signalRService,
      );

      await provider.handleSignalREvent({
        'eventType': 'match.assigned',
        'payload': {
          'matchId': 'match-1',
          'statusCode': 'countdown',
          'serverTime': '2026-07-27T03:00:00Z',
        },
      });

      expect(provider.matchmakingState, PvpMatchmakingState.countdown);
      expect(provider.currentMatch?.matchId, 'match-1');
      expect(datasource.fetchedMatchIds, contains('match-1'));
      expect(signalRService.joinedMatchIds, contains('match-1'));
    },
  );
}
