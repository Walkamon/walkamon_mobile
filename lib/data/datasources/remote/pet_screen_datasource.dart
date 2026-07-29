import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/pet_evolution_models.dart';
import '../../models/pet_name_response.dart';
import '../../models/pet_status_response.dart';

class PetScreenDatasource {
  PetScreenDatasource([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<PetStatusResponse>> getPetStatus() async {
    return _apiClient.get<PetStatusResponse>(
      ApiConstants.petStatus,
      fromJsonT: (json) =>
          PetStatusResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<PetNameResponse>> getPetName() async {
    return _apiClient.get<PetNameResponse>(
      ApiConstants.petName,
      fromJsonT: (json) =>
          PetNameResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<PetNameResponse>> createStarterPet(String petName) async {
    return _apiClient.post<PetNameResponse>(
      ApiConstants.createStarterPet,
      data: {'petName': petName},
      fromJsonT: (json) =>
          PetNameResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<PetStatusResponse>> tapSpirit() async {
    return _apiClient.post<PetStatusResponse>(
      ApiConstants.petTap,
      fromJsonT: (json) =>
          PetStatusResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<PetStatusResponse>> feedSpirit() async {
    return _apiClient.post<PetStatusResponse>(
      ApiConstants.petFeed,
      fromJsonT: (json) =>
          PetStatusResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<PetOverviewResponse>> getPetOverview() async {
    return _apiClient.get<PetOverviewResponse>(
      '/api/pet/me',
      fromJsonT: (json) =>
          PetOverviewResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<List<PetEvolutionStageResponse>>>
  getEvolutionStages() async {
    final resp = await _apiClient.get<List<PetEvolutionStageResponse>>(
      '/api/pet/evolution/stages',
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map>()
              .map(
                (item) => PetEvolutionStageResponse.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
        return <PetEvolutionStageResponse>[];
      },
    );

    // Ensure callers always get a non-null list when the response is marked
    // successful. Some backend responses may wrap `data: null` which would
    // result in ApiResponse.data == null — normalize that to an empty list.
    if (resp.success && resp.data == null) {
      return ApiResponse<List<PetEvolutionStageResponse>>(
        success: resp.success,
        status: resp.status,
        message: resp.message,
        data: <PetEvolutionStageResponse>[],
        traceId: resp.traceId,
      );
    }

    return resp;
  }

  Future<ApiResponse<List<PetEvolutionHistoryResponse>>>
  getEvolutionHistory() async {
    final resp = await _apiClient.get<List<PetEvolutionHistoryResponse>>(
      '/api/pet/evolution/history',
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map>()
              .map(
                (item) => PetEvolutionHistoryResponse.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
        return <PetEvolutionHistoryResponse>[];
      },
    );

    if (resp.success && resp.data == null) {
      return ApiResponse<List<PetEvolutionHistoryResponse>>(
        success: resp.success,
        status: resp.status,
        message: resp.message,
        data: <PetEvolutionHistoryResponse>[],
        traceId: resp.traceId,
      );
    }

    return resp;
  }

  Future<ApiResponse<PetCurrentAnimationResponse>> getCurrentAnimation() async {
    return _apiClient.get<PetCurrentAnimationResponse>(
      '/api/pet/current-animation',
      fromJsonT: (json) => PetCurrentAnimationResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<List<PetEvolutionOptionResponse>>> getEvolutionOptions() async {
    final resp = await _apiClient.get<List<PetEvolutionOptionResponse>>(
      '/api/pet/evolution/options',
      fromJsonT: (json) {
        if (json is List) {
          return json
              .whereType<Map>()
              .map(
                (item) => PetEvolutionOptionResponse.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
        return <PetEvolutionOptionResponse>[];
      },
    );

    if (resp.success && resp.data == null) {
      return ApiResponse<List<PetEvolutionOptionResponse>>(
        success: resp.success,
        status: resp.status,
        message: resp.message,
        data: <PetEvolutionOptionResponse>[],
        traceId: resp.traceId,
      );
    }

    return resp;
  }

  Future<ApiResponse<Map<String, dynamic>>> evolveToFamily(String petId) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/api/pet/evolution',
      data: {'petId': petId},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> evolveToNextStage() async {
    return _apiClient.post<Map<String, dynamic>>('/api/pet/evolution/next');
  }
}
