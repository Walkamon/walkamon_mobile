import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/pvp_models.dart';

class PvpSprintDatasource {
  PvpSprintDatasource([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<List<PvpMatchResponse>>> getMatchHistory({
    int page = 1,
    int pageSize = 20,
    String matchType = 'ranked',
  }) async {
    return _apiClient.get<List<PvpMatchResponse>>(
      '/api/pvp/sprint/matches',
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
      '/api/pvp/sprint/invites',
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
}