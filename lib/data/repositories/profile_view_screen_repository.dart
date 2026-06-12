import '../models/profile_view_response.dart';
import '../datasources/remote/profile_view_screen_datasource.dart';

class ProfileViewScreenRepository {
  final ProfileViewScreenDatasource _remoteDatasource;

  ProfileViewScreenRepository(this._remoteDatasource);

  /// Lấy thông tin profile và bóc tách ApiResponse thành Model dữ liệu sạch
  Future<ProfileViewResponse> getUserProfile() async {
    final apiResponse = await _remoteDatasource.getProfileData();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    } else {
      throw Exception(
        apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Không thể tải thông tin tài khoản.',
      );
    }
  }
}
