import '../../models/notification_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

abstract class NotificationDatasource {
  Future<NotificationResponse> updateNotification(bool enabled);
}

class NotificationDatasourceImpl implements NotificationDatasource {
  final ApiClient apiClient;

  NotificationDatasourceImpl(this.apiClient);

  @override
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
}
