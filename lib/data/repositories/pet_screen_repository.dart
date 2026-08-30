import '../../core/network/app_failure.dart';
import '../datasources/remote/pet_screen_datasource.dart';
import '../models/pet_evolution_models.dart';
import '../models/pet_name_response.dart';
import '../models/pet_status_response.dart';

class PetFeedException extends AppFailure {
  const PetFeedException({
    required super.code,
    required super.status,
    super.params,
    super.fallbackMessage,
    super.traceId,
  });
}

class PetScreenRepository {
  PetScreenRepository({PetScreenDatasource? datasource})
    : _datasource = datasource ?? PetScreenDatasource();

  final PetScreenDatasource _datasource;

  Future<PetStatusResponse> getPetStatus() async {
    final apiResponse = await _datasource.getPetStatus();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<bool> getStoryStatus() async {
    final apiResponse = await _datasource.getStoryStatus();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<PetNameResponse?> getPetName() async {
    final apiResponse = await _datasource.getPetName();

    if (apiResponse.success) {
      return apiResponse.data;
    }

    if (apiResponse.status == 404) return null;

    throw apiResponse.failure;
  }

  Future<PetNameResponse?> createStarterPet(String petName) async {
    final apiResponse = await _datasource.createStarterPet(petName);

    if (apiResponse.success) {
      return apiResponse.data ?? PetNameResponse(petId: '', petName: petName);
    }

    if (apiResponse.errorCode == 'PET_ALREADY_EXISTS') {
      return getPetName();
    }

    throw apiResponse.failure;
  }

  Future<PetStatusResponse> tapSpirit() async {
    final apiResponse = await _datasource.tapSpirit();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<PetStatusResponse> feedSpirit() async {
    final apiResponse = await _datasource.feedSpirit();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    final failure = apiResponse.failure;
    throw PetFeedException(
      code: failure.code,
      status: failure.status,
      params: failure.params,
      fallbackMessage: failure.fallbackMessage,
      traceId: failure.traceId,
    );
  }

  Future<PetOverviewResponse> getPetOverview() async {
    final apiResponse = await _datasource.getPetOverview();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<List<PetEvolutionStageResponse>> getEvolutionStages() async {
    final apiResponse = await _datasource.getEvolutionStages();

    if (apiResponse.success) {
      return apiResponse.data ?? <PetEvolutionStageResponse>[];
    }

    throw apiResponse.failure;
  }

  Future<List<PetEvolutionHistoryResponse>> getEvolutionHistory() async {
    final apiResponse = await _datasource.getEvolutionHistory();

    if (apiResponse.success) {
      return apiResponse.data ?? <PetEvolutionHistoryResponse>[];
    }

    throw apiResponse.failure;
  }

  Future<PetCurrentAnimationResponse> getCurrentAnimation() async {
    final apiResponse = await _datasource.getCurrentAnimation();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw apiResponse.failure;
  }

  Future<bool> evolveToNextStage() async {
    final apiResponse = await _datasource.evolveToNextStage();
    return apiResponse.success;
  }

  Future<List<PetEvolutionOptionResponse>> getEvolutionOptions() async {
    final apiResponse = await _datasource.getEvolutionOptions();

    if (apiResponse.success) {
      return apiResponse.data ?? <PetEvolutionOptionResponse>[];
    }

    throw apiResponse.failure;
  }

  Future<bool> evolveToFamily(String petId) async {
    final apiResponse = await _datasource.evolveToFamily(petId);
    return apiResponse.success;
  }

  Future<List<PetEvolutionPreviewResponse>> getEvolutionPreviews() async {
    final apiResponse = await _datasource.getEvolutionPreviews();

    if (apiResponse.success) {
      return apiResponse.data ?? <PetEvolutionPreviewResponse>[];
    }

    throw apiResponse.failure;
  }
}
