/*
   Định nghĩa một cấu trúc phản hồi chuẩn từ Server trả về (ví dụ: tất cả API từ server đều trả về dạng { "status": true, "message": "Thành công", "data": ... }). File này giúp bạn parse dữ liệu bao bọc đó một cách tự động.
*/

class ApiResponse<T> {
  final bool success;
  final int status;
  final String message;
  final T? data;
  final String? traceId;

  ApiResponse({
    required this.success,
    required this.status,
    required this.message,
    this.data,
    this.traceId,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    // 1. Lấy message chuẩn nếu có
    String parsedMessage = json['message']?.toString() ?? '';

    // 2. Xử lý trường hợp backend C# trả về lỗi FluentValidation (RFC 7807 ProblemDetails)
    if (parsedMessage.isEmpty && json.containsKey('errors') && json['errors'] is Map) {
      final Map<String, dynamic> validationErrors = json['errors'];
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
    } else if (parsedMessage.isEmpty && json.containsKey('title')) {
      // Fallback lấy title của lỗi HTTP
      parsedMessage = json['title'].toString();
    }

    return ApiResponse<T>(
      success: json['success'] ?? false,
      status: json['status'] ?? 0,
      message: parsedMessage,
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : null,
      traceId: json['traceId'] as String?,
    );
  }
}
