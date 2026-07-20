import '../datasources/remote/pet_screen_datasource.dart';
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
}
