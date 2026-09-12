import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/auth/token_storage.dart';
import 'package:walkamon_mobile/core/network/dio_provider.dart';
import 'package:walkamon_mobile/data/repositories/change_password_screen_repository.dart';

class PasswordAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'success': status == 200,
        'status': status,
        'message': status == 200
            ? 'Change password success'
            : 'Current password is invalid',
        'data': null,
      }),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Repository uses authenticated PUT with exactly CurrentPassword/NewPassword, no OTP API',
    () async {
      final dio = DioProvider.instance,
          oldAdapter = DioProvider.instance.httpClientAdapter;
      final oldToken = TokenStorage.token;
      final adapter = PasswordAdapter();
      dio.httpClientAdapter = adapter;
      TokenStorage.setToken('test-token-not-a-real-credential');
      addTearDown(() {
        dio.httpClientAdapter = oldAdapter;
        TokenStorage.setToken(oldToken);
      });
      final repository = ChangePasswordScreenRepository();
      final result = await repository.changePassword(
        currentPassword: ' OldPass7! ',
        newPassword: ' NewPass8@ ',
      );
      expect(result.success, isTrue);
      expect(result.status, 200);
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/api/auth/change-password');
      expect(
        request.headers['Authorization'],
        'Bearer test-token-not-a-real-credential',
      );
      expect(request.data, {
        'CurrentPassword': ' OldPass7! ',
        'NewPassword': ' NewPass8@ ',
      });
      expect(TokenStorage.token, 'test-token-not-a-real-credential');
      adapter.status = 400;
      final rejected = await repository.changePassword(
        currentPassword: 'Wrong7!',
        newPassword: 'NewPass8@',
      );
      expect(rejected.success, isFalse);
      expect(rejected.status, 400);
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests.every(
          (r) => r.method == 'PUT' && r.path == '/api/auth/change-password',
        ),
        isTrue,
      );
    },
  );
}
