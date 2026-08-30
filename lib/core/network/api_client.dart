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
        message: e.message ?? 'Network connection failed.',
        errorCode: _networkErrorCode(e),
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: 'Unexpected client error.',
        errorCode: 'UNEXPECTED_RESPONSE',
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
      return _parseResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      if (e.response != null) {
        return _parseResponse<T>(e.response!, fromJsonT);
      }
      return ApiResponse<T>(
        success: false,
        status: e.response?.statusCode ?? 0,
        message: e.message ?? 'Network connection failed.',
        errorCode: _networkErrorCode(e),
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: 'Unexpected client error.',
        errorCode: 'UNEXPECTED_RESPONSE',
      );
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
        message: e.message ?? 'Network connection failed.',
        errorCode: _networkErrorCode(e),
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: 'Unexpected client error.',
        errorCode: 'UNEXPECTED_RESPONSE',
      );
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
        message: e.message ?? 'Network connection failed.',
        errorCode: _networkErrorCode(e),
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: 'Unexpected client error.',
        errorCode: 'UNEXPECTED_RESPONSE',
      );
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
        message: e.message ?? 'Network connection failed.',
        errorCode: _networkErrorCode(e),
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        status: -1,
        message: 'Unexpected client error.',
        errorCode: 'UNEXPECTED_RESPONSE',
      );
    }
  }

  ApiResponse<T> _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic json)? fromJsonT,
  ) {
    if (response.data is Map<String, dynamic>) {
      final json = response.data as Map<String, dynamic>;
      final hasSuccess =
          json.containsKey('success') || json.containsKey('Success');
      final hasStatus =
          json.containsKey('status') || json.containsKey('Status');
      final hasMessage =
          json.containsKey('message') || json.containsKey('Message');
      final hasData = json.containsKey('data') || json.containsKey('Data');
      final hasTraceId =
          json.containsKey('traceId') || json.containsKey('TraceId');
      final isWrappedResponse =
          hasSuccess || hasStatus || hasMessage || hasTraceId;

      if (!isWrappedResponse) {
        return ApiResponse<T>(
          success: true,
          status: response.statusCode ?? 200,
          message: 'Success',
          data: fromJsonT != null ? fromJsonT(json) : null,
        );
      }

      final hasOnlySuccessMessage =
          hasMessage && !hasSuccess && !hasStatus && !hasData && !hasTraceId;
      final statusCode = response.statusCode ?? 0;

      if (hasOnlySuccessMessage && statusCode >= 200 && statusCode < 300) {
        return ApiResponse<T>(
          success: true,
          status: statusCode,
          message:
              (json['message'] ?? json['Message'])?.toString() ?? 'Success',
        );
      }

      return ApiResponse<T>.fromJson(
        json,
        fromJsonT,
        defaultStatus: statusCode,
      );
    }

    if (response.data is List) {
      return ApiResponse<T>(
        success: true,
        status: response.statusCode ?? 200,
        message: 'Success',
        data: fromJsonT != null ? fromJsonT(response.data) : null,
      );
    }

    return ApiResponse<T>(
      success: false,
      status: response.statusCode ?? 0,
      message: 'The response format is invalid.',
      errorCode: 'UNEXPECTED_RESPONSE',
    );
  }

  String _networkErrorCode(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => 'REQUEST_TIMEOUT',
    _ => 'NETWORK_UNAVAILABLE',
  };
}
