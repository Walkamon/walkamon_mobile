import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _googleServerClientId =
    '644682972598-d5h58a3b0g8c0ag6lm1bcdf9k5mh4vch.apps.googleusercontent.com';

class GoogleSignInAuth {
  GoogleSignInAuth._();

  static Future<void>? _initFuture;

  static Future<String> getIdToken() async {
    _initFuture ??= GoogleSignIn.instance.initialize(
      clientId: _googleServerClientId,
      serverClientId: kIsWeb ? null : _googleServerClientId,
    );
    await _initFuture;

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this platform.');
    }

    final googleUser = await GoogleSignIn.instance.authenticate(
      scopeHint: const ['email', 'profile'],
    );
    final idToken = googleUser.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Khong lay duoc Google idToken.');
    }

    return idToken;
  }
}
