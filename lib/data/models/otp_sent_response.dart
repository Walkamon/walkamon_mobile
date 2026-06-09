class OtpSentResponse {
  final String requestCode;
  final DateTime expiresAtUtc;
  final DateTime resendAvailableAtUtc;

  OtpSentResponse({
    required this.requestCode,
    required this.expiresAtUtc,
    required this.resendAvailableAtUtc,
  });

  factory OtpSentResponse.fromJson(Map<String, dynamic> json) {
    return OtpSentResponse(
      requestCode: json['requestCode'] as String? ?? '',
      expiresAtUtc: _parseUtcDateTime(json['expiresAtUtc']),
      resendAvailableAtUtc: _parseUtcDateTime(json['resendAvailableAtUtc']),
    );
  }

  static DateTime _parseUtcDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value).toUtc();
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}