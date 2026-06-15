import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_provider.dart';

class SettingScreenDatasource {
  final Dio _dio = DioProvider.instance;

  Future<bool> logout() async {
    try {
      final response = await _dio.post(ApiConstants.logout);
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<bool> sendFeedback({
    required String content,
    required String feedbackTypeCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.userFeedback,
        data: {'Content': content, 'FeedbackTypeCode': feedbackTypeCode},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    }
  }
}
