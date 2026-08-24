import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/pvp_models.dart';
import '../../models/pvp_item_models.dart';

class PvpSprintDatasource {
  PvpSprintDatasource([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// UC-70 — paginated match history.
  /// Default `includeActive=false` → only `finished` and `cancelled`.
  Future<ApiResponse<PvpMatchHistoryPage>> getMatchHistory({
    int page = 1,
    int pageSize = 20,
    String matchType = '',
    String result = '',
    DateTime? from,
    DateTime? to,
    bool includeActive = false,
  }) async {
    return _apiClient.get<PvpMatchHistoryPage>(
      ApiConstants.pvpSprintMatches,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (matchType.isNotEmpty) 'matchType': matchType,
        if (result.isNotEmpty) 'result': result,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        'includeActive': includeActive.toString(),
      },
      fromJsonT: (json) {
        if (json is Map<String, dynamic>) {
          return PvpMatchHistoryPage.fromJson(json);
        }
        if (json is List) {
          return PvpMatchHistoryPage(
            page: page,
            pageSize: pageSize,
            total: json.length,
            items: json
                .map(
                  (e) => PvpMatchResponse.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          );
        }
        return PvpMatchHistoryPage(
          page: page,
          pageSize: pageSize,
          total: 0,
          items: const [],
        );
      },
    );
  }

  /// UC-73 — list invites (direction: incoming|sent, status: pending|accepted|declined|cancelled|expired).
  Future<ApiResponse<PvpInvitePage>> getInvites({
    String direction = 'incoming',
    String? status = 'pending',
    int page = 1,
    int pageSize = 20,
  }) async {
    return _apiClient.get<PvpInvitePage>(
      ApiConstants.pvpSprintInvites,
      queryParameters: {
        'direction': direction,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
      fromJsonT: (json) {
        if (json is Map<String, dynamic>) {
          return PvpInvitePage.fromJson(json);
        }
        return PvpInvitePage(
          page: page,
          pageSize: pageSize,
          total: 0,
          items: [],
        );
      },
    );
  }

  Future<ApiResponse<List<PvpInviteResponse>>> getIncomingInvites({
    int page = 1,
    int pageSize = 20,
    String? status = 'pending',
  }) async {
    final pageResp = await getInvites(
      direction: 'incoming',
      status: status,
      page: page,
      pageSize: pageSize,
    );
    if (pageResp.success && pageResp.data != null) {
      return ApiResponse<List<PvpInviteResponse>>(
        success: true,
        status: pageResp.status,
        message: pageResp.message,
        data: pageResp.data!.items,
      );
    }
    return ApiResponse<List<PvpInviteResponse>>(
      success: false,
      status: pageResp.status,
      message: pageResp.message,
      data: [],
    );
  }

  Future<ApiResponse<List<PvpInviteResponse>>> getSentInvites({
    int page = 1,
    int pageSize = 20,
    String? status = 'pending',
  }) async {
    final pageResp = await getInvites(
      direction: 'sent',
      status: status,
      page: page,
      pageSize: pageSize,
    );
    if (pageResp.success && pageResp.data != null) {
      return ApiResponse<List<PvpInviteResponse>>(
        success: true,
        status: pageResp.status,
        message: pageResp.message,
        data: pageResp.data!.items,
      );
    }
    return ApiResponse<List<PvpInviteResponse>>(
      success: false,
      status: pageResp.status,
      message: pageResp.message,
      data: [],
    );
  }

  /// UC-67 — create sprint invite.
  Future<ApiResponse<PvpInviteResponse>> createInvite(
    String targetUserId,
  ) async {
    return _apiClient.post<PvpInviteResponse>(
      ApiConstants.pvpSprintInvites,
      data: {'targetUserId': targetUserId},
      fromJsonT: (json) =>
          PvpInviteResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// UC-67 — accept or decline sprint invite.
  Future<ApiResponse<PvpInviteResponse>> respondToInvite(
    String inviteId, {
    required bool accept,
  }) async {
    return _apiClient.post<PvpInviteResponse>(
      '${ApiConstants.pvpSprintInvites}/$inviteId/response',
      data: {'accept': accept},
      fromJsonT: (json) =>
          PvpInviteResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// UC-67 — cancel pending sprint invite.
  Future<ApiResponse<void>> cancelInvite(String inviteId) async {
    return _apiClient.delete<void>(
      '${ApiConstants.pvpSprintInvites}/$inviteId',
    );
  }

  Future<ApiResponse<PvpMatchResponse>> startMatchmaking() async {
    return _apiClient.post<PvpMatchResponse>(
      ApiConstants.pvpSprintMatchmaking,
      data: {'matchTypeCode': 'ranked'},
      fromJsonT: (json) =>
          PvpMatchResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PvpMatchmakingStatusResponse>>
  getMatchmakingStatus() async {
    return _apiClient.get<PvpMatchmakingStatusResponse>(
      ApiConstants.pvpSprintMatchmakingStatus,
      fromJsonT: (json) =>
          PvpMatchmakingStatusResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> cancelMatchmaking() async {
    return _apiClient.delete<void>(ApiConstants.pvpSprintMatchmaking);
  }

  Future<ApiResponse<PvpMatchResponse>> getMatch(String matchId) async {
    return _apiClient.get<PvpMatchResponse>(
      ApiConstants.pvpSprintMatchById(matchId),
      fromJsonT: (json) =>
          PvpMatchResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PvpLoadoutResponse>> getLoadout() async {
    return _apiClient.get<PvpLoadoutResponse>(
      ApiConstants.pvpSprintLoadout,
      fromJsonT: (json) => PvpLoadoutResponse.fromJson(json),
    );
  }

  Future<ApiResponse<PvpLoadoutResponse>> updateLoadout(
    List<PvpLoadoutSlot> slots,
  ) async {
    return _apiClient.put<PvpLoadoutResponse>(
      ApiConstants.pvpSprintLoadout,
      data: {
        'slots': slots
            .map(
              (slot) => <String, dynamic>{
                'slotNo': slot.slotNo,
                if (slot.itemId != null) 'itemId': slot.itemId,
              },
            )
            .toList(growable: false),
      },
      fromJsonT: (json) => PvpLoadoutResponse.fromJson(json),
    );
  }

  Future<ApiResponse<PvpItemActionResponse>> useItem(
    String matchId, {
    required int slotNo,
    required String clientActionId,
  }) async {
    return _apiClient.post<PvpItemActionResponse>(
      ApiConstants.pvpSprintMatchItems(matchId),
      data: <String, dynamic>{
        'slotNo': slotNo,
        'clientActionId': clientActionId,
      },
      fromJsonT: (json) => PvpItemActionResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  /// Forfeit / leave an active sprint match. Caller is marked lose; opponent win.
  Future<ApiResponse<PvpMatchResponse>> forfeitMatch(String matchId) async {
    return _apiClient.post<PvpMatchResponse>(
      '${ApiConstants.pvpSprintMatchById(matchId)}/forfeit',
      fromJsonT: (json) =>
          PvpMatchResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PvpMatchResultResponse>> getMatchResult(
    String matchId,
  ) async {
    return _apiClient.get<PvpMatchResultResponse>(
      '${ApiConstants.pvpSprintMatchById(matchId)}/result',
      fromJsonT: (json) =>
          PvpMatchResultResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PvpRewardClaimResponse>> claimMatchReward(
    String matchId,
  ) async {
    return _apiClient.post<PvpRewardClaimResponse>(
      '${ApiConstants.pvpSprintMatchById(matchId)}/reward-claim',
      fromJsonT: (json) =>
          PvpRewardClaimResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> submitMatchStepSession(
    String matchId, {
    required String platformCode,
    required String sensorModeCode,
  }) async {
    return _apiClient.post<dynamic>(
      '${ApiConstants.pvpSprintMatchById(matchId)}/step-session',
      data: {'platformCode': platformCode, 'sensorModeCode': sensorModeCode},
    );
  }

  Future<ApiResponse<dynamic>> submitStepBatches(
    String matchId,
    String sessionId,
    List<dynamic> batches,
  ) async {
    return _apiClient.post<dynamic>(
      '${ApiConstants.pvpSprintMatchById(matchId)}/step-sessions/$sessionId/batches',
      data: batches,
    );
  }
}
