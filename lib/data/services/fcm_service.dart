import 'package:firebase_messaging/firebase_messaging.dart';
import '../repositories/notification_repository.dart';

class FCMService {
  final NotificationRepository _notificationRepo;

  FCMService(this._notificationRepo);

  /// Gọi hàm này NGAY SAU KHI đăng nhập thành công
  Future<void> setupToken() async {
    try {
      // 1. Xin quyền hiển thị thông báo (Cần thiết cho iOS & Android 13+)
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Lấy Token từ Firebase
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null && fcmToken.isNotEmpty) {
          // 3. Gửi Token lên Backend
          await _notificationRepo.registerDeviceToken(fcmToken);
          // print("Đã đăng ký FCM Token thành công: $fcmToken");
        }

        // 4. Lắng nghe nếu Token thay đổi thì tự động gửi lại lên Backend
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await _notificationRepo.registerDeviceToken(newToken);
          // print("FCM Token đã được refresh: $newToken");
        });
      }
    } catch (e) {
      print("Lỗi khi setup FCM Token: $e");
    }
  }

  /// Gọi hàm này TRƯỚC KHI thực hiện xóa dữ liệu local để đăng xuất
  Future<void> deactivateToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _notificationRepo.deactivateDeviceToken(fcmToken);
        print("Đã hủy kích hoạt FCM Token thành công");
      }
    } catch (e) {
      print("Lỗi khi hủy FCM Token: $e");
    }
  }
}
