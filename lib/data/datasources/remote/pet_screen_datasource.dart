import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/pet_status_response.dart';

class PetScreenDatasource {
  PetScreenDatasource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<PetStatusResponse>> getPetStatus() async {
    return _apiClient.get<PetStatusResponse>(
      '/api/Pet/status',
      fromJsonT: (json) => PetStatusResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<PetStatusResponse>> tapSpirit() async {
    return _apiClient.post<PetStatusResponse>(
      '/api/Pet/tap',
      fromJsonT: (json) => PetStatusResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<PetStatusResponse>> feedSpirit() async {
    return _apiClient.post<PetStatusResponse>(
      '/api/Pet/feed',
      fromJsonT: (json) => PetStatusResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}
