import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/profile_view_response.dart';

class ProfileViewScreenDatasource {
  final ApiClient _apiClient;

  ProfileViewScreenDatasource(this._apiClient);

  /// Gọi API lấy thông tin profile của player hiện tại
  Future<ApiResponse<ProfileViewResponse>> getProfileData() async {
    return await _apiClient.get<ProfileViewResponse>(
      '/api/auth/profile',
      fromJsonT: (json) =>
          ProfileViewResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
