/*
   Định nghĩa một cấu trúc phản hồi chuẩn từ Server trả về (ví dụ: tất cả API từ server đều trả về dạng { "status": true, "message": "Thành công", "data": ... }). File này giúp bạn parse dữ liệu bao bọc đó một cách tự động.
*/

class ApiResponse<T> {
  final bool success;
  final int status;
  final String message;
  final String? errorCode;
  final Map<String, dynamic> params;
  final T? data;
  final String? traceId;

  ApiResponse({
    required this.success,
    required this.status,
    required this.message,
    this.errorCode,
    this.params = const <String, dynamic>{},
    this.data,
    this.traceId,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT, {
    int? defaultStatus,
  }) {
    dynamic read(String camelKey, String pascalKey) {
      if (json.containsKey(camelKey)) return json[camelKey];
      return json[pascalKey];
    }

    // 1. Lấy message chuẩn nếu có
    String parsedMessage = read('message', 'Message')?.toString() ?? '';

    // 2. Xử lý trường hợp backend C# trả về lỗi FluentValidation (RFC 7807 ProblemDetails)
    final errors = read('errors', 'Errors');
    if (parsedMessage.isEmpty && errors is Map) {
      final Map<String, dynamic> validationErrors = Map<String, dynamic>.from(
        errors,
      );
      List<String> allMessages = [];

      validationErrors.forEach((key, value) {
        if (value is List) {
          allMessages.addAll(value.map((item) => item.toString()));
        } else if (value is String) {
          allMessages.add(value);
        }
      });

      if (allMessages.isNotEmpty) {
        parsedMessage = allMessages.join(', ');
      }
    } else if (parsedMessage.isEmpty && read('title', 'Title') != null) {
      // Fallback lấy title của lỗi HTTP
      parsedMessage = read('title', 'Title').toString();
    }

    final rawSuccess = read('success', 'Success');
    final rawStatus = read('status', 'Status');
    final rawData = read('data', 'Data');
    final statusValue =
        int.tryParse(rawStatus?.toString() ?? '') ?? defaultStatus ?? 0;

    final successValue =
        rawSuccess == true ||
        rawSuccess?.toString() == 'true' ||
        (rawSuccess == null &&
            rawStatus == null &&
            statusValue >= 200 &&
            statusValue < 300);

    return ApiResponse<T>(
      success: successValue,
      status: statusValue,
      message: parsedMessage,
      errorCode: read('errorCode', 'ErrorCode')?.toString(),
      params: _parseParams(read('params', 'Params')),
      data: (rawData != null && fromJsonT != null) ? fromJsonT(rawData) : null,
      traceId: read('traceId', 'TraceId')?.toString(),
    );
  }

  static Map<String, dynamic> _parseParams(dynamic raw) {
    if (raw is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.unmodifiable(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }
}
