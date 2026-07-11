class NotificationResponse {
  final bool notificationsEnabled;
  final DateTime? updatedAt;

  NotificationResponse({required this.notificationsEnabled, this.updatedAt});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

class NotificationItem {
  final String notificationId;
  final String title;
  final String shortBody;
  final DateTime createdAt;
  bool isRead;
  final String? typeCode;

  NotificationItem({
    required this.notificationId,
    required this.title,
    required this.shortBody,
    required this.createdAt,
    required this.isRead,
    this.typeCode,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notificationId']?.toString() ?? '',
      title: json['title'] ?? '', //[cite: 2]
      shortBody: json['shortBody'] ?? '', //[cite: 2]
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false, //[cite: 2]
      typeCode: json['typeCode'], //[cite: 2]
    );
  }
}
