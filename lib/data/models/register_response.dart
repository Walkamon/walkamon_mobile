class RegisterResponse {
  final String requestCode;
  final String expiresAtUtc;
  final String resendAvailableAtUtc;

  RegisterResponse({
    required this.requestCode,
    required this.expiresAtUtc,
    required this.resendAvailableAtUtc,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      requestCode: json['requestCode'] as String? ?? '',
      expiresAtUtc: json['expiresAtUtc'] as String? ?? '',
      resendAvailableAtUtc: json['resendAvailableAtUtc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestCode': requestCode,
      'expiresAtUtc': expiresAtUtc,
      'resendAvailableAtUtc': resendAvailableAtUtc,
    };
  }
}
