import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/pvp_models.dart';

class PvpSprintDatasource {
  PvpSprintDatasource([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<List<PvpMatchResponse>>> getMatchHistory({
    int page = 1,
    int pageSize = 20,
    String matchType = 'ranked',
    String result = '',
    bool includeActive = false,
  }) async {
    return _apiClient.get<List<PvpMatchResponse>>(
      ApiConstants.pvpSprintMatches,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'matchType': matchType,
        if (result.isNotEmpty) 'result': result,
        'includeActive': includeActive.toString(),
      },
      fromJsonT: (json) {
        if (json is Map<String, dynamic> && json['items'] != null) {
          final items = json['items'] as List;
          return items
              .map((e) => PvpMatchResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<ApiResponse<List<PvpInviteResponse>>> getIncomingInvites({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _apiClient.get<List<PvpInviteResponse>>(
      ApiConstants.pvpSprintInvites,
      queryParameters: {
        'direction': 'incoming',
        'status': 'pending',
        'page': page,
        'pageSize': pageSize,
      },
      fromJsonT: (json) {
        if (json is Map<String, dynamic> && json['items'] != null) {
          final items = json['items'] as List;
          return items
              .map((e) => PvpInviteResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<ApiResponse<List<PvpInviteResponse>>> getSentInvites({
    int page = 1,
    int pageSize = 20,
  }) async {
    return _apiClient.get<List<PvpInviteResponse>>(
      ApiConstants.pvpSprintInvites,
      queryParameters: {
        'direction': 'sent',
        'status': 'pending',
        'page': page,
        'pageSize': pageSize,
      },
      fromJsonT: (json) {
        if (json is Map<String, dynamic> && json['items'] != null) {
          final items = json['items'] as List;
          return items
              .map((e) => PvpInviteResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

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
