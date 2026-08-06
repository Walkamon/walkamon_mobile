class ForgotPasswordResetTicketResponse {
  final String resetToken;
  final String requestCode;
  final DateTime expiresAtUtc;

  const ForgotPasswordResetTicketResponse({
    required this.resetToken,
    required this.requestCode,
    required this.expiresAtUtc,
  });

  factory ForgotPasswordResetTicketResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawExpiresAt = json['expiresAtUtc'] ?? json['expiresAt'];
    final expiresAt = rawExpiresAt is String && rawExpiresAt.isNotEmpty
        ? DateTime.parse(rawExpiresAt).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return ForgotPasswordResetTicketResponse(
      resetToken: json['resetToken'] as String? ?? '',
      requestCode: json['requestCode'] as String? ?? '',
      expiresAtUtc: expiresAt,
    );
  }
}
