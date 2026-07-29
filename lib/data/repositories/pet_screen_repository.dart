import '../datasources/remote/pet_screen_datasource.dart';
import '../models/pet_evolution_models.dart';
import '../models/pet_name_response.dart';
import '../models/pet_status_response.dart';

class PetScreenRepository {
  PetScreenRepository({PetScreenDatasource? datasource})
    : _datasource = datasource ?? PetScreenDatasource();

  final PetScreenDatasource _datasource;

  Future<PetStatusResponse> getPetStatus() async {
    final apiResponse = await _datasource.getPetStatus();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải trạng thái thú cưng.',
    );
  }

  Future<PetNameResponse?> getPetName() async {
    final apiResponse = await _datasource.getPetName();

    if (apiResponse.success) {
      return apiResponse.data;
    }

    if (apiResponse.status == 404) return null;

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'KhÃ´ng thá»ƒ táº£i tÃªn thÃº cÆ°ng.',
    );
  }

  Future<PetNameResponse?> createStarterPet(String petName) async {
    final apiResponse = await _datasource.createStarterPet(petName);

    if (apiResponse.success) {
      return apiResponse.data ?? PetNameResponse(petId: '', petName: petName);
    }

    final message = apiResponse.message.toLowerCase();
    if (apiResponse.status == 400 && message.contains('already has a pet')) {
      return getPetName();
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'KhÃ´ng thá»ƒ táº¡o thÃº cÆ°ng khá»Ÿi Ä‘áº§u.',
    );
  }

  Future<PetStatusResponse> tapSpirit() async {
    final apiResponse = await _datasource.tapSpirit();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể nhấp vào thú cưng.',
    );
  }

  Future<PetStatusResponse> feedSpirit() async {
    final apiResponse = await _datasource.feedSpirit();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể cho thú cưng ăn.',
    );
  }

  Future<PetOverviewResponse> getPetOverview() async {
    final apiResponse = await _datasource.getPetOverview();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải thông tin tiến hóa thú cưng.',
    );
  }

  Future<List<PetEvolutionStageResponse>> getEvolutionStages() async {
    final apiResponse = await _datasource.getEvolutionStages();

    if (apiResponse.success) {
      return apiResponse.data ?? <PetEvolutionStageResponse>[];
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải giai đoạn tiến hóa.',
    );
  }

  Future<List<PetEvolutionHistoryResponse>> getEvolutionHistory() async {
    final apiResponse = await _datasource.getEvolutionHistory();

    if (apiResponse.success) {
      return apiResponse.data ?? <PetEvolutionHistoryResponse>[];
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải lịch sử tiến hóa.',
    );
  }

  Future<PetCurrentAnimationResponse> getCurrentAnimation() async {
    final apiResponse = await _datasource.getCurrentAnimation();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải animation hiện tại.',
    );
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

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải tùy chọn tiến hóa.',
    );
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

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải xem trước tiến hóa.',
    );
  }
}
