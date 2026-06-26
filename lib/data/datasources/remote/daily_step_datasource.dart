import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_provider.dart';

class DailyStepDatasource {
  DailyStepDatasource({Dio? dio}) : _dio = dio ?? DioProvider.instance;

  final Dio _dio;

  Future<bool> syncStepDelta(int stepCount) async {
    if (stepCount <= 0) return true;

    try {
      final response = await _dio.post(
        ApiConstants.dailySteps,
        data: {'stepCount': stepCount},
      );
      final status = response.statusCode ?? 0;
      return status >= 200 && status < 300;
    } on DioException {
      return false;
    }
  }
}
