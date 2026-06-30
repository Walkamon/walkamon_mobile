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
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      if (e.response != null) {
        return _parseResponse<T>(e.response!, fromJsonT);
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(success: false, status: -1, message: e.toString());
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      if (e.response != null) {
        return _parseResponse<T>(e.response!, fromJsonT);
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(success: false, status: -1, message: e.toString());
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      if (e.response != null) {
        return _parseResponse<T>(e.response!, fromJsonT);
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(success: false, status: -1, message: e.toString());
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      if (e.response != null) {
        return _parseResponse<T>(e.response!, fromJsonT);
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(success: false, status: -1, message: e.toString());
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.delete(path, data: data);
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      if (e.response != null) {
        return _parseResponse<T>(e.response!, fromJsonT);
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Đã xảy ra lỗi kết nối mạng.',
      );
    } catch (e) {
      return ApiResponse<T>(success: false, status: -1, message: e.toString());
    }
  }

  ApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic json)? fromJsonT,
  ) {
    if (response.data is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT,
      );
    }

    if (response.data is List) {
      return ApiResponse<T>(
        success: true,
        status: response.statusCode ?? 200,
        message: 'Thành công',
        data: fromJsonT != null ? fromJsonT(response.data) : null,
      );
    }

    return ApiResponse<T>(
      success: false,
      status: response.statusCode ?? 0,
      message: 'Dữ liệu phản hồi không đúng định dạng.',
    );
  }
}
