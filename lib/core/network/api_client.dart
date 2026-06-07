/*
  Nhiệm vụ: Bọc lại (wrapper) các hàm của Dio. Nó cung cấp các hàm ngắn gọn như get(), post(), put(), delete() để các file khác gọi API một cách đồng nhất.
*/

import 'package:dio/dio.dart';
import 'dio_provider.dart';
import 'api_response.dart';

class ApiClient {
  final Dio _dio = DioProvider.instance;

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      
      if (response.data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(
          response.data as Map<String, dynamic>,
          fromJsonT,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          status: response.statusCode ?? 0,
          message: 'Dữ liệu phản hồi không đúng định dạng.',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(
          e.response!.data as Map<String, dynamic>,
          fromJsonT,
        );
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      
      if (response.data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(
          response.data as Map<String, dynamic>,
          fromJsonT,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          status: response.statusCode ?? 0,
          message: 'Dữ liệu phản hồi không đúng định dạng.',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        return ApiResponse<T>.fromJson(
          e.response!.data as Map<String, dynamic>,
          fromJsonT,
        );
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: e.toString(),
      );
    }
  }
}
