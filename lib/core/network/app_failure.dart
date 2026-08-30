import 'api_response.dart';

class AppFailure implements Exception {
  const AppFailure({
    required this.code,
    required this.status,
    this.params = const <String, dynamic>{},
    this.fallbackMessage = '',
    this.traceId,
  });

  final String code;
  final int status;
  final Map<String, dynamic> params;
  final String fallbackMessage;
  final String? traceId;

  factory AppFailure.fromResponse(ApiResponse<dynamic> response) {
    return AppFailure(
      code: response.errorCode?.trim().isNotEmpty == true
          ? response.errorCode!.trim().toUpperCase()
          : _fallbackCodeForStatus(response.status),
      status: response.status,
      params: response.params,
      fallbackMessage: response.message,
      traceId: response.traceId,
    );
  }

  static String _fallbackCodeForStatus(int status) => switch (status) {
    400 => 'BAD_REQUEST',
    401 => 'UNAUTHORIZED',
    403 => 'FORBIDDEN',
    404 => 'NOT_FOUND',
    409 => 'CONFLICT',
    429 => 'TOO_MANY_REQUESTS',
    >= 500 => 'INTERNAL_ERROR',
    _ => 'UNEXPECTED_RESPONSE',
  };

  @override
  String toString() => 'AppFailure($code, status: $status, traceId: $traceId)';
}

extension ApiResponseFailure<T> on ApiResponse<T> {
  AppFailure get failure => AppFailure.fromResponse(this);
}
