import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../models/register_response.dart';

class RegisterScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<RegisterResponse>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final Map<String, dynamic> body = {
      'email': email,
      'username': username,
      'password': password,
    };

    return await _apiClient.post<RegisterResponse>(
      ApiConstants.register,
      data: body,
      fromJsonT: (json) =>
          RegisterResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
