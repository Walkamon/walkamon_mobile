import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/constants/api_constants.dart';
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


  Future<ApiResponse<void>> updateTheme(String themeCode) async {
    return await _apiClient.patch<void>(
      ApiConstants.profileTheme,
      data: {'themeCode': themeCode},
    );
  }

  /// Gửi dữ liệu cập nhật hồ sơ lên hệ thống C# Backend
  Future<ApiResponse<ProfileViewResponse>> updateProfileData({
    required String username,
    required String bio,
    required String gender,
    required String dob,
    Uint8List? imageBytes,
  }) async {
    // ── CHUẨN HÓA GIÁ TRỊ GENDER SANG TIẾNG ANH THEO QUY ĐỊNH CỦA API ──
    String apiGender = 'other';
    final normalizedGender = gender.trim().toLowerCase();

    if (normalizedGender == 'nam' || normalizedGender == 'male') {
      apiGender = 'male';
    } else if (normalizedGender == 'nữ' ||
        normalizedGender == 'nu' ||
        normalizedGender == 'female') {
      apiGender = 'female';
    }
    // 1. Khởi tạo một Map chứa thông tin text thông thường trước
    // Tên field phải dùng PascalCase theo đúng quy ước của Backend C#
    final Map<String, dynamic> dataMap = {
      'Username': username,
      'Bio': bio,
      'Gender': apiGender,
      'Dob': dob,
    };

    // 2. Kiểm tra nếu người dùng có chọn ảnh mới (imageBytes khác null), đính kèm file vào Map dữ liệu
    if (imageBytes != null) {
      dataMap['Image'] = MultipartFile.fromBytes(
        imageBytes,
        filename: 'avatar.jpg',
        contentType: MediaType(
          'image',
          'jpeg',
        ), // Khai báo MIME type để Backend C# nhận dạng đúng file ảnh
      );
    }

    // 3. Đóng gói toàn bộ dataMap thành FormData và gửi qua hàm put lên API
    return await _apiClient.put<ProfileViewResponse>(
      '/api/auth/profile',
      data: FormData.fromMap(dataMap), // Gửi cục FormData có kèm ảnh
      fromJsonT: (json) =>
          ProfileViewResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
