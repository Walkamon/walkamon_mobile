import '../../models/notification_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

abstract class NotificationDatasource {
  Future<NotificationResponse> updateNotification(bool enabled);
  Future<List<NotificationItem>> getNotifications(int page, int pageSize);
  Future<NotificationDetail> getNotificationDetail(String id);
  Future<void> registerDeviceToken(String fcmToken);
  Future<void> deactivateDeviceToken(String fcmToken);
}

class NotificationDatasourceImpl implements NotificationDatasource {
  final ApiClient apiClient;

  NotificationDatasourceImpl(this.apiClient);

  @override
  Future<void> registerDeviceToken(String fcmToken) async {
    final response = await apiClient.post(
      ApiConstants.registerDeviceToken,
      data: {'fcmToken': fcmToken}, //
    );
    if (!response.success) throw Exception(response.message);
  }

  @override
  Future<void> deactivateDeviceToken(String fcmToken) async {
    final response = await apiClient.post(
      ApiConstants.deactivateDeviceToken,
      data: {'fcmToken': fcmToken}, //
    );
    if (!response.success) throw Exception(response.message);
  }

  Future<NotificationResponse> updateNotification(bool enabled) async {
    try {
      // 1. Thêm <NotificationResponse> và truyền fromJsonT để ApiClient biết cách dịch JSON
      final response = await apiClient.patch<NotificationResponse>(
        ApiConstants.updateNotification,
        data: {'notificationsEnabled': enabled},
        fromJsonT: (json) =>
            NotificationResponse.fromJson(json as Map<String, dynamic>),
      );

      // 2. Kiểm tra cờ success
      if (!response.success) {
        throw Exception(response.message ?? "Lỗi cập nhật thông báo");
      }

      // 3. Lúc này response.data đã được ApiClient tự động parse thành NotificationResponse
      if (response.data == null) {
        throw Exception("Không đọc được dữ liệu trả về từ server");
      }

      return response.data!;
    } catch (e) {
      print("Lỗi NotificationDatasource: $e");
      rethrow;
    }
  }

  Future<NotificationDetail> getNotificationDetail(String id) async {
    try {
      final response = await apiClient.get<NotificationDetail>(
        '/api/notifications/$id',
        fromJsonT: (json) =>
            NotificationDetail.fromJson(json as Map<String, dynamic>),
      );

      if (!response.success) {
        throw Exception(response.message ?? "Lỗi tải chi tiết thông báo");
      }

      return response.data!;
    } catch (e) {
      print("Lỗi getNotificationDetail: $e");
      rethrow;
    }
  }

  Future<List<NotificationItem>> getNotifications(
    int page,
    int pageSize,
  ) async {
    try {
      final response = await apiClient.get<List<NotificationItem>>(
        '${ApiConstants.getNotifications}?page=$page&pageSize=$pageSize', //[cite: 2]
        fromJsonT: (json) {
          final data = json as Map<String, dynamic>;
          final list = data['notifications'] as List; //[cite: 2]
          return list
              .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

      if (!response.success) {
        throw Exception(response.message ?? "Lỗi tải thông báo");
      }

      return response.data ?? [];
    } catch (e) {
      print("Lỗi getNotifications: $e");
      rethrow;
    }
  }
}
