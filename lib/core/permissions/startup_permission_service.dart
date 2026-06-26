import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef PermissionRequest = Future<void> Function();

class StartupPermissionService {
  StartupPermissionService({PermissionRequest? permissionRequest})
    : _permissionRequest = permissionRequest ?? _requestAndroidPermissions;

  static const _requestCompletedKey = 'startup_permissions_requested_v1';

  final PermissionRequest _permissionRequest;

  Future<void> requestOnce() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_requestCompletedKey) ?? false) return;

      await _permissionRequest();
      await preferences.setBool(_requestCompletedKey, true);
    } catch (_) {
      // Platform plugins are unavailable in some tests and unsupported targets.
      // Leave the flag unset so Android can try again on the next real launch.
    }
  }

  static Future<void> _requestAndroidPermissions() async {
    await <Permission>[
      Permission.activityRecognition,
    ].request();
  }
}
