import 'dart:typed_data';
import 'package:dio/dio.dart';
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

  Future<void> updateTheme(String themeCode) async {
    final normalized = themeCode.trim().toLowerCase();
    if (!{'light', 'dark', 'system'}.contains(normalized)) {
      throw ArgumentError.value(themeCode, 'themeCode');
    }
    final response = await _remoteDatasource.updateTheme(normalized);
    if (!response.success) throw Exception(response.message);
  }

  /// Xử lý cập nhật thông tin và kiểm tra trạng thái thành công/thất bại
  Future<void> updateUserProfile({
    required String username,
    required String gender,
    required String dob,
    required String bio,
    Uint8List? imageBytes,
  }) async {
    final apiResponse = await _remoteDatasource.updateProfileData(
      username: username,
      gender: gender,
      dob: dob,
      bio: bio,
      imageBytes: imageBytes,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Không thể cập nhật hồ sơ.',
      );
    }
  }
}
