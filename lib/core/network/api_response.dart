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
    return ApiResponse<T>(
      success: json['success'] ?? false,
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : null,
      traceId: json['traceId'] as String?,
    );
  }
}
