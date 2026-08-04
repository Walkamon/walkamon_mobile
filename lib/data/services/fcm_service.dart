import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repositories/notification_repository.dart';

class FCMService {
  FCMService(this._notificationRepo);

  final NotificationRepository _notificationRepo;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isActive = false;

  static const String _vapidKey =
      'BMxWbOxZH9lDYXnxLUxI3UwzpetJuohK-CyakFI_AvCiroNhLe2tifo3-J8dKuB5UeftPcT1wL2n5sJn2sITR8c';

  /// Requests OS/browser permission and registers this device only if granted.
  /// The settings toggle must remain off when this method returns false.
  Future<bool> setupToken() async {
    debugPrint(
      '[NotificationFlow][FCM] request_permission '
      'platform=${kIsWeb ? 'web' : 'native'}',
    );

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '[NotificationFlow][FCM] permission_result='
        '${settings.authorizationStatus.name}',
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!granted) {
        _isActive = false;
        await _cancelTokenRefreshListener();
        debugPrint('[NotificationFlow][FCM] activation_stopped=permission_denied');
        return false;
      }

      debugPrint('[NotificationFlow][FCM] requesting_device_token');
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (token == null || token.isEmpty) {
        _isActive = false;
        await _cancelTokenRefreshListener();
        debugPrint('[NotificationFlow][FCM] activation_stopped=token_empty');
        return false;
      }

      debugPrint(
        '[NotificationFlow][FCM] token_ready length=${token.length}',
      );
      await _notificationRepo.registerDeviceToken(token);
      debugPrint('[NotificationFlow][FCM] backend_token_registered=true');

      _isActive = true;
      await _listenForTokenRefresh();
      debugPrint('[NotificationFlow][FCM] activation_complete=true');
      return true;
    } catch (error) {
      _isActive = false;
      await _cancelTokenRefreshListener();
      debugPrint('[NotificationFlow][FCM] activation_failed error=$error');
      return false;
    }
  }

  Future<void> _listenForTokenRefresh() async {
    await _cancelTokenRefreshListener();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        if (!_isActive || newToken.isEmpty) return;
        debugPrint(
          '[NotificationFlow][FCM] token_refreshed length=${newToken.length}',
        );
        try {
          await _notificationRepo.registerDeviceToken(newToken);
          debugPrint('[NotificationFlow][FCM] refreshed_token_registered=true');
        } catch (error) {
          debugPrint(
            '[NotificationFlow][FCM] refreshed_token_failed error=$error',
          );
        }
      },
      onError: (Object error) {
        debugPrint('[NotificationFlow][FCM] token_stream_failed error=$error');
      },
    );
    debugPrint('[NotificationFlow][FCM] token_refresh_listener=active');
  }

  Future<void> _cancelTokenRefreshListener() async {
    final hadListener = _tokenRefreshSubscription != null;
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    if (hadListener) {
      debugPrint('[NotificationFlow][FCM] token_refresh_listener=cancelled');
    }
  }

  /// Stops push delivery without displaying a new permission prompt.
  Future<void> deactivateToken() async {
    debugPrint('[NotificationFlow][FCM] deactivation_started');
    _isActive = false;
    await _cancelTokenRefreshListener();

    try {
      if (kIsWeb) {
        final settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        final granted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
        debugPrint(
          '[NotificationFlow][FCM] deactivation_permission='
          '${settings.authorizationStatus.name}',
        );
        if (!granted) {
          debugPrint(
            '[NotificationFlow][FCM] deactivation_skipped=no_browser_permission',
          );
          return;
        }
      }

      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (token == null || token.isEmpty) {
        debugPrint('[NotificationFlow][FCM] deactivation_skipped=token_empty');
        return;
      }

      await _notificationRepo.deactivateDeviceToken(token);
      debugPrint('[NotificationFlow][FCM] backend_token_deactivated=true');
    } catch (error) {
      debugPrint('[NotificationFlow][FCM] deactivation_failed error=$error');
    }
  }
}
