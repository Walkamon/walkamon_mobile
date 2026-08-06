import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/forgot_password_reset_ticket_response.dart';

void main() {
  test('parses reset ticket response from backend contract', () {
    final response = ForgotPasswordResetTicketResponse.fromJson({
      'resetToken': 'ticket-123',
      'requestCode': 'request-456',
      'expiresAtUtc': '2026-08-07T01:10:00Z',
    });

    expect(response.resetToken, 'ticket-123');
    expect(response.requestCode, 'request-456');
    expect(response.expiresAtUtc, DateTime.utc(2026, 8, 7, 1, 10));
  });

  test('accepts expiresAt fallback used by older server serializers', () {
    final response = ForgotPasswordResetTicketResponse.fromJson({
      'resetToken': 'ticket-123',
      'requestCode': 'request-456',
      'expiresAt': '2026-08-07T01:10:00+00:00',
    });

    expect(response.expiresAtUtc, DateTime.utc(2026, 8, 7, 1, 10));
  });
}
