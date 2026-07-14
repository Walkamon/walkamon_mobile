import '../datasources/remote/pet_screen_datasource.dart';
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
