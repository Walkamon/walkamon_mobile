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
  }) async {
    return _apiClient.get<List<PvpMatchResponse>>(
      ApiConstants.pvpSprintMatches,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'matchType': matchType,
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

  Future<ApiResponse<PvpMatchResponse>> startMatchmaking() async {
    return _apiClient.post<PvpMatchResponse>(
      ApiConstants.pvpSprintMatchmaking,
      data: {'matchTypeCode': 'ranked'},
      fromJsonT: (json) =>
          PvpMatchResponse.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<void>> respondToInvite({
    required String inviteId,
    required bool accepted,
  }) async {
    return _apiClient.post<void>(
      ApiConstants.pvpSprintInviteResponse(inviteId),
      data: {'accepted': accepted},
    );
  }
}
