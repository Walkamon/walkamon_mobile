import '../datasources/remote/notification_datasource.dart';
import '../../data/models/notification_response.dart';

abstract class NotificationRepository {
  Future<NotificationResponse> updateNotification(bool enabled);
  Future<void> registerDeviceToken(String fcmToken);
  Future<void> deactivateDeviceToken(String fcmToken);
  Future<NotificationDetail> getNotificationDetail(String id);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDatasource datasource;

  NotificationRepositoryImpl({required this.datasource});

  @override
  Future<NotificationResponse> updateNotification(bool enabled) {
    return datasource.updateNotification(enabled);
  }

  @override
  Future<NotificationDetail> getNotificationDetail(String id) {
    return datasource.getNotificationDetail(id);
  }

  @override
  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      await datasource.registerDeviceToken(fcmToken);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deactivateDeviceToken(String fcmToken) async {
    try {
      await datasource.deactivateDeviceToken(fcmToken);
    } catch (e) {
      rethrow;
    }
  }
}
