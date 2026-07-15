import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../repositories/notification_repository.dart';

class FCMService {
  final NotificationRepository _notificationRepo;

  // Khai báo VAPID Key thành một biến hằng số để dùng chung, dễ quản lý và không bị hardcode lặp lại
  static const String _vapidKey =
      'BMxWbOxZH9lDYXnxLUxI3UwzpetJuohK-CyakFI_AvCiroNhLe2tifo3-J8dKuB5UeftPcT1wL2n5sJn2sITR8c';

  FCMService(this._notificationRepo);

  /// Gọi hàm này NGAY SAU KHI đăng nhập thành công
  Future<void> setupToken() async {
    try {
      // print("=== ĐÃ CHẠY VÀO HÀM SETUPTOKEN ===");
      // 1. Xin quyền hiển thị thông báo (Cần thiết cho iOS & Android 13+)
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Lấy Token từ Firebase (Truyền VAPID Key cho Web)
        String? fcmToken = await FirebaseMessaging.instance.getToken(
          vapidKey: _vapidKey,
        );

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
      // Kiểm tra quyền trên Web, nếu chưa cấp quyền thì không gọi getToken
      // để tránh việc trình duyệt hiện popup bắt người dùng cho phép thông báo
      if (kIsWeb) {
        NotificationSettings settings =
            await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          print("Quyền thông báo chưa được cấp, bỏ qua hủy FCM Token.");
          return;
        }
      } 

      // Thêm vapidKey vào đây để Web lấy Token cũ đi hủy không bị lỗi
      String? fcmToken = await FirebaseMessaging.instance.getToken(
        vapidKey: _vapidKey,
      );

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _notificationRepo.deactivateDeviceToken(fcmToken);
        print("Đã hủy kích hoạt FCM Token thành công");
      }
    } catch (e) {
      print("Lỗi khi hủy FCM Token: $e");
    }
  }
}
