import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
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
}
