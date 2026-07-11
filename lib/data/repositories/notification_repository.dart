import '../datasources/remote/notification_datasource.dart';
import '../../data/models/notification_response.dart';

abstract class NotificationRepository {
  Future<NotificationResponse> updateNotification(bool enabled);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDatasource datasource;

  NotificationRepositoryImpl({required this.datasource});

  @override
  Future<NotificationResponse> updateNotification(bool enabled) {
    return datasource.updateNotification(enabled);
  }
}
